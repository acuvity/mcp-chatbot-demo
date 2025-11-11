import os
import asyncio
import threading

from opentelemetry import trace

from mcp.types import PromptMessage, TextContent
from mcp_agent.core.fastagent import FastAgent
from mcp_agent.core.request_params import RequestParams
from mcp_agent.mcp.prompt_message_multipart import PromptMessageMultipart
from mcp_agent.mcp.helpers.content_helpers import get_text
from mcp_agent.logging.logger import get_logger

class AgentService:
    """Agentic Service for handling asynchronous agent requests."""
    def __init__(self, config: str | None = None) -> None:

        # Process Configurations
        self.config = config or os.environ.get("AGENT_CONFIG_PATH")
        # Handle YAML configuration if provided
        yconfig = os.environ.get("AGENT_CONFIG_YAML")
        if yconfig:
            import tempfile
            # Create a temporary file
            with tempfile.NamedTemporaryFile(mode='w+', delete=False) as temp:
                print(f"Temporary file created at: {temp.name}")
                temp.write(yconfig)
                self.config = temp.name
                self.logger.info(f"Configuration file created at: {temp.name}")
                self.logger.info(f"Configuration content: {yconfig}")

        self.running = True
        self.history = True
        self.logger = get_logger(__name__)
        self.logger.info("Agentic Runner initializing...")

        # Initialize asyncio event loop and thread. All asyncio tasks will run in this loop.
        # This allows us to run async code in a synchronous context.
        self.loop = asyncio.new_event_loop()
        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

        self.tracer = trace.get_tracer(__name__)
        self.logger.info("Agentic Runner initialized...")

    def _run(self):
        asyncio.set_event_loop(self.loop)
        # Schedule the main runner coroutine
        self.loop.create_task(self.runner())
        self.loop.run_forever()

    async def runner(self):

        # Run this service once and process multiple requests
        self.agent = None
        self.running = True

        self.fast_agent = FastAgent(
            "Acuvity Agent",
            config_path=self.config,
        )

        server_keys = {}
        try:
            server_keys = self.fast_agent.config.get("mcp").get("servers").keys()
        except Exception as e:
            self.logger.error(f"Error getting server keys: {e}")

        @self.fast_agent.agent(
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
            servers=server_keys,
            request_params=RequestParams(
                use_history=True, max_iterations=10000
            ),
        )
        async def dummy(self):
            # This function is needed for the decorator but not used directly
            pass

        async with self.fast_agent.run() as agent:
            self.agent = agent
            while self.running:
                await asyncio.sleep(3600)  # Keep alive

        self.logger.warning("Agentic Runner stopped")


    async def process_message(self, message: str) -> str:
        """Asynchronous send method to process messages."""

        if not self.agent:
            self.logger.debug("Agent is not initialized.")
            return "error: agent not initialized"

        self.logger.info(
            f"running agentic runner with span-context: {trace.get_current_span().get_span_context()} {message}"
        )

        try:
            prompts = PromptMessageMultipart.to_multipart(
                [
                    PromptMessage(
                        role="user",
                        content=TextContent(type="text", text=message),
                    ),
                ]
            )
            response = await self.agent.acuvity.generate(
                multipart_messages=prompts,
                request_params=RequestParams(use_history=self.history, max_iterations=10000),
            )

            # Use history until explicitly cleared
            self.history = True

            # Format the response
            response_text = "Sorry, I couldn't find any information on that."
            for content in response.content:
                response_text = get_text(content)
            return response_text
        except Exception as e:
            # Handle errors - could put them on the output queue too
            response = f"error: {e}, original_message: {message}"
        return response

    def send(self, message, block=True, timeout=None) -> str:
        """Send a message in the background loop"""
        fut = asyncio.run_coroutine_threadsafe(self.process_message(message), self.loop)
        return fut.result(timeout=timeout) if block else None

    def clear(self) -> str:
        """Clear the agentic history in the same loop"""
        self.logger.info("history clearing...")
        self.history = False
        return "clear"

agent_service = AgentService()