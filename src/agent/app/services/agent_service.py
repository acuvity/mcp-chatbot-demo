import asyncio
import os
import threading

from mcp.types import PromptMessage, TextContent
from mcp_agent.core.request_params import RequestParams
from mcp_agent.core.fastagent import FastAgent
from mcp_agent.logging.logger import get_logger

from opentelemetry import trace

class AgentService:

    CLEAR = "clear"

    def __init__(self, config: str | None = None) -> None:
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
        self.logger = get_logger(__name__)

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

        self.thread = threading.Thread(target=self._run, daemon=True)
        self.thread.start()

    def _run(self):
        asyncio.run(self.runner())

    async def runner(self):
        """Instantiate an instance of the agent that can be reused."""
        async with self.fast_agent.run() as agent:
            self.agent = agent
            while True:
                if not self.running:
                    self.logger.info("Exiting agent...")
                    return
                await asyncio.sleep(3600)  # Keep alive

    async def _asend(self, message: str) -> str:
        """Asynchronous send method to process messages."""
        if not self.agent:
            self.logger.debug("Agent is not initialized.")
            return "error: agent not initialized"

        self.logger.info(
            f"running agentic runner with span-context: {trace.get_current_span().get_span_context()} {message}"
        )

        try:
            response = await self.agent.send(
                PromptMessage(
                    role="user",
                    content=TextContent(type="text", text=message),
                ),
            )
        except Exception as e:
            # Handle errors - could put them on the output queue too
            response = f"error: {e}, original_message: {message}"
        return response

    def stop(self):
        self.running = False

    def send(self, message, block=True, timeout=None) -> str | None:
        """send a message"""
        return asyncio.run(self._asend(message))

    def clear(self):
        """clear the agentic history"""
        self.logger.warning("history clearing not implemented...")

agent_service = AgentService()