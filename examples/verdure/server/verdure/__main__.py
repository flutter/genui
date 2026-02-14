# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import logging
import os

import click
from a2a.server.apps import A2AStarletteApplication
from a2a.server.request_handlers import DefaultRequestHandler
from a2a.server.tasks import InMemoryTaskStore
from a2a.types import AgentCapabilities, AgentCard, AgentSkill
from a2ui_ext import a2uiExtension
from agent import LandscapeAgent
from agent_executor import LandscapeAgentExecutor
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from starlette.staticfiles import StaticFiles

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class MissingAPIKeyError(Exception):
    """Exception for missing API key."""


@click.command()
@click.option("--host", default="localhost")
@click.option("--port", default=10002, help="The port to bind to.")
@click.option("--base-url", help="The public base URL for the agent card. Use when running on an Android emulator so you can override the default host with 10.0.2.2, for instance.")
def main(host: str, port: int, base_url: str | None):
    """Runs the Verdure landscape design agent server."""
    try:
        # Check for API key only if Vertex AI is not configured
        if not os.getenv("GOOGLE_GENAI_USE_VERTEXAI") == "TRUE":
            if not os.getenv("GEMINI_API_KEY"):
                raise MissingAPIKeyError(
                    "GEMINI_API_KEY environment variable not set and GOOGLE_GENAI_USE_VERTEXAI is not TRUE."
                )

        hello_ext = a2uiExtension()
        capabilities = AgentCapabilities(
            streaming=True,
            extensions=[
                hello_ext.agent_extension(),
            ],
        )
        skill = AgentSkill(
            id="design_landscape",
            name="Landscape Design Tool",
            description="Helps users design a landscape by guiding them through preferences and options.",
            tags=["landscape", "design", "garden"],
            examples=["Design my backyard", "Start a new landscape project"],
        )

        if base_url is None:
            base_url = f"http://{host}:{port}"

        agent_card = AgentCard(
            name="A2UIScape Design",
            description="This agent helps you envision your dream landscape.",
            url=base_url,  # <-- Use base_url here
            version="1.0.0",
            default_input_modes=LandscapeAgent.SUPPORTED_CONTENT_TYPES,
            default_output_modes=LandscapeAgent.SUPPORTED_CONTENT_TYPES,
            capabilities=capabilities,
            skills=[skill],
        )

        agent_executor = LandscapeAgentExecutor(base_url=base_url)

        agent_executor = hello_ext.wrap_executor(agent_executor)

        request_handler = DefaultRequestHandler(
            agent_executor=agent_executor,
            task_store=InMemoryTaskStore(),
        )
        server = A2AStarletteApplication(
            agent_card=agent_card, http_handler=request_handler
        )
        import uvicorn

        app = server.build()

        app.add_middleware(
            CORSMiddleware,
            allow_origins=["http://localhost:5173"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

        import pathlib
        current_dir = pathlib.Path(__file__).parent.resolve()
        images_dir = current_dir / "images"
        app.mount("/images", StaticFiles(directory=images_dir), name="images")

        uvicorn.run(app, host=host, port=port)
    except MissingAPIKeyError as e:
        logger.error(f"Error: {e}")
        exit(1)
    except Exception as e:
        logger.error(f"An error occurred during server startup: {e}")
        exit(1)


if __name__ == "__main__":
    main()
