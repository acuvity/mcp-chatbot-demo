from app.agentic import AgenticRunner
import os


class AgentService(AgenticRunner):
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
        super().__init__(config_path=self.config)

agent_service = AgentService()