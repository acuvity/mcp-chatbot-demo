import asyncio
import os
import queue
import re
import threading

from mcp_agent.agents.agent import Agent, AgentConfig
from mcp_agent.app import MCPApp
from mcp_agent.logging.logger import get_logger
from mcp_agent.llm.providers.augmented_llm_anthropic import (
    AnthropicAugmentedLLM,  # noqa: F401
)
from mcp_agent.core.request_params import RequestParams
from mcp_agent.mcp.helpers.content_helpers import get_text

from opentelemetry import trace
from opentelemetry.trace import set_span_in_context, NonRecordingSpan


class ContextPropagatingQueue(queue.Queue):
    def put(self, item, block=True, timeout=None):
        """Capture context and attach it to the item."""
        current_span = trace.get_current_span()
        ctx = current_span.get_span_context()
        super().put((item, ctx), block, timeout)

    def get(self, block=True, timeout=None):
        """Restore context when getting item."""
        item, ctx = super().get(block, timeout)

        parent_span = NonRecordingSpan(ctx)
        new_context = set_span_in_context(parent_span)

        return item, new_context


class AgenticRunner:

    CLEAR = "clear"

    def __init__(self, config_path: str = None):
        self.running = True
        self.input_queue = ContextPropagatingQueue()
        self.output_queue = queue.Queue()
        self.config_path = config_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "fastagent.config.yaml"
        )

        self.history = True
        self.logger = get_logger(__name__)

        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

        # Tracer
        self.tracer = trace.get_tracer(__name__)

        self.logger.info("Agentic Runner initialized")

    async def runner(self):
        # Demo App
        app = MCPApp(
            name="mcp_generic_agent",
            settings=self.config_path,
        )

        async with app.run() as application:

            servers = list(application.config.mcp.servers.keys())
            if not servers:
                servers = []
            self.logger.info(f"Available servers: {servers}")

            agent_config = AgentConfig(
                name="acuvity",
                instruction="""You are an agent with the following:
                - ability to fetch URLs
                - access to internet searches
                - access to github repositories
                - ability for sequential thinking
                - ability to test simple and complex prompts and other operations
                - access to memory
                Your job is to identify the closest match to a user's request,
                make the appropriate tool calls, and return the information requested by the user.""",
                servers=servers,
                model="sonnet",
            )

            basic_agent = Agent(config=agent_config)

            async with basic_agent:
                llm = await basic_agent.attach_llm(AnthropicAugmentedLLM)
                while self.running:
                    await self.process_message(llm)

    def _run(self):
        asyncio.run(self.runner())

    def stop(self):
        self.running = False

    async def process_message(self, llm):
        rx_message, ctx = self.input_queue.get(block=True)
        try:
            if rx_message == AgenticRunner.CLEAR:
                self.history = False
                self.output_queue.put(AgenticRunner.CLEAR)
            else:
                with self.tracer.start_as_current_span("agentic_runner", context=ctx):
                    self.logger.info(
                        f"running agentic runner with span-context: {trace.get_current_span().get_span_context()} {rx_message}"
                    )
                    tx_message = await llm.generate_messages(
                        message_param={
                            "role": "user",
                            "content": rx_message,
                        },
                        request_params=RequestParams(
                            use_history=self.history, max_iterations=10000
                        ),
                    )
                    self.history = True
                    response_text = "Sorry, I couldn't find any information on that."
                    # Get last text content from the response
                    for content in tx_message.content:
                        response_text = get_text(content)
                    self.output_queue.put(response_text)
        except Exception as e:
            # Handle errors - could put them on the output queue too
            self.output_queue.put({"error": str(e), "original_message": rx_message})

    def send(self, message, block=True, timeout=None) -> str | None:
        """send a message"""
        self.input_queue.put(message)
        try:
            response = self.output_queue.get(block=block, timeout=timeout)
        except queue.Empty:
            response = f"send: error: {message}"
        return response

    def clear(self):
        """clear the agentic history"""
        self.logger.info("history clearing...")
        self.input_queue.put(AgenticRunner.CLEAR)
        self.output_queue.get(block=True, timeout=1)
        self.logger.info("history cleared...")