from app.agentic import AgenticRunner
import os


class AgentService(AgenticRunner):
    def __init__(self, config: str | None = None) -> None:
        self.config = config or os.environ.get("AGENT_CONFIG_PATH")
        super().__init__(config_path=self.config)

agent_service = AgentService()