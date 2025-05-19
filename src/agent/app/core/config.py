import os
from typing import List, Optional
from pydantic import BaseModel

# Logging and Open Telemetry Setup
import logging
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.trace import set_tracer_provider
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.threading import ThreadingInstrumentor
from openinference.instrumentation.mcp import MCPInstrumentor

class Settings(BaseModel):
    PROJECT_NAME: str = "Chat API"
    API_V1_STR: str = "/api/v1"

    # ENVIRONMENT
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

    # SECURITY
    ACCESS_TOKEN_SECURITY_KEY: str = os.getenv("ACCESS_TOKEN_SECURITY_KEY", "your-secret-key-change-this")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # DATABASE
    POSTGRES_SERVER: str = os.getenv("POSTGRES_SERVER", "localhost")
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "chat_db")
    POSTGRES_PORT: int = int(os.getenv("POSTGRES_PORT", 5432))
    SQLALCHEMY_DATABASE_URI: Optional[str] = None

    # LOGGING
    LOGGING_LEVEL_STR: str = os.getenv("LOGGING_LEVEL", "WARNING")
    LOGGING_LEVEL: int = logging.getLevelNamesMapping()[LOGGING_LEVEL_STR]

    OTEL_ENABLED: bool = os.getenv("OTEL_ENABLED", False)
    OTEL_NO_FILE_EXPORT: bool = os.getenv("OTEL_FILE_EXPORT", False)
    OTLE_FILE: str = os.getenv("OTLE_FILE", "otel.jsonl")

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    # DESCOPE
    DESCOPE_BASE_URI: str = os.getenv("DESCOPE_BASE_URI", "https://api.descope.com")
    DESCOPE_PROJECT_ID: str = os.getenv("DESCOPE_PROJECT_ID", None)

    def __init__(self, **data):
        super().__init__(**data)
        self.__initialize__()
        self.SQLALCHEMY_DATABASE_URI = self.build_db_connection()

    def __initialize__(self):
        logging.getLogger("httpx").setLevel(self.LOGGING_LEVEL)
        logging.getLogger("mcp").setLevel(self.LOGGING_LEVEL)

        # Initialize logging/traces/otel
        logging.basicConfig(level=logging.INFO)
        logger = logging.getLogger(__name__)

        ## Export OpenTelemetry
        if self.OTEL_ENABLED:
            from opentelemetry.sdk.resources import SERVICE_NAME, Resource
            from opentelemetry.sdk.trace.export import (
                ConsoleSpanExporter,
                SimpleSpanProcessor,
            )
            trace.set_tracer_provider(
                TracerProvider(
                    resource=Resource.create({SERVICE_NAME: "mcp-agentic-chatbot"})
                )
            )
            if not self.OTEL_NO_FILE_EXPORT:
                from .exporter import FileSpanExporter
                span_processor = SimpleSpanProcessor(
                    FileSpanExporter(file_path=self.OTLE_FILE)
                )
            else:
                span_processor = SimpleSpanProcessor(ConsoleSpanExporter())
            trace.get_tracer_provider().add_span_processor(span_processor)
        else:
            provider = TracerProvider()
            set_tracer_provider(provider)
        HTTPXClientInstrumentor().instrument()
        ThreadingInstrumentor().instrument()
        MCPInstrumentor().instrument()

        logger.info("Logger initialized")

    def build_db_connection(self) -> str:
        """Build PostgreSQL connection string"""
        if os.getenv("SQLALCHEMY_DATABASE_URI"):
            return os.getenv("SQLALCHEMY_DATABASE_URI")

        return f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

# Load settings from environment variables
settings = Settings()