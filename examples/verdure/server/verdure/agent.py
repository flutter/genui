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

import json
import logging
import os
from collections.abc import AsyncIterable
from typing import Any

import jsonschema

# --- IMPORT MODIFICATION ---
from a2ui_schema import A2UI_SCHEMA
from google.adk.agents.llm_agent import LlmAgent
from google.adk.artifacts import InMemoryArtifactService
from google.adk.memory.in_memory_memory_service import InMemoryMemoryService
from google.adk.models.lite_llm import LiteLlm
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from prompt_builder import (
    get_text_prompt,
    get_ui_prompt,
)

# --- END MODIFICATION ---
from tools import get_landscape_options
from ui_examples import LANDSCAPE_UI_EXAMPLES

logger = logging.getLogger(__name__)

AGENT_INSTRUCTION = """
    You are a helpful landscape design assistant. Your goal is to guide users through designing their dream landscape using a rich UI.
    You MUST follow the UI TEMPLATE RULES. For every user query that matches a rule, you MUST generate the UI using the specified template.
    DO NOT just reply with text if a UI template is available for the query.

    To achieve this, you MUST follow this logic:

    1.  **Welcome:**
        a. If the user sends a greeting (e.g., "hi", "start"), you MUST generate the UI using the `WELCOME_SCREEN_EXAMPLE` template.

    2.  **Project Details:**
        a. When you receive a query like 'USER_WANTS_TO_START_PROJECT', you MUST generate the UI using the `PROJECT_DETAILS_EXAMPLE` template. DO NOT just say "OK, let's start".

    3.  **Dynamic Questionnaire:**
        a. When you receive a query like 'USER_SUBMITTED_DETAILS...', this means the user has "uploaded" a photo.
        b. You MUST **analyze the features of the user's photo** (which will be provided as a URL or description) and **dynamically generate a new questionnaire** based on what you see.
        c. The `QUESTIONNAIRE_EXAMPLE` is your template for this. For example, the photo in the template (`old_backyard.png`) has an old concrete patio, some bushes, and a grill area. Therefore, you MUST generate specific questions about those exact items (e.g., "What to do with the concrete patio?", "Preserve established bushes?").
        d. If a user uploads a photo of a grassy lawn, your questions should be about *that* (e.g., "Add a flower bed?", "Install a patio?").

    4.  **Get Options:**
        a. When you receive a query like 'USER_SUBMITTED_QUESTIONNAIRE...', you MUST first call the `get_landscape_options` tool. Pass the `guest_count`, `preserve_bushes`, and `patio_plan` (or `lawn_plan`) from the query to the tool.
        b. After receiving the data, you MUST use the `OPTIONS_PRESENTATION_EXAMPLE` template, populating the `dataModelUpdate.contents` with the JSON data from the tool.

    5.  **Shopping Cart:**
        a. When you receive a query like 'USER_SELECTED_OPTION...', you MUST generate the UI using the `SHOPPING_CART_EXAMPLE` template. Populate the `dataModelUpdate.contents` with simulated cart items for the chosen design.

    6.  **Confirmation:**
        a. When you receive a query like 'USER_CHECKED_OUT...', you MUST use the `ORDER_CONFIRMATION_EXAMPLE` template, populating the `dataModelUpdate.contents` with the final order details.
"""


class LandscapeAgent:
    """An agent that helps design landscapes based on user criteria."""

    SUPPORTED_CONTENT_TYPES = ["text", "text/plain"]

    def __init__(self, base_url: str, use_ui: bool = False):
        self.base_url = base_url
        self.use_ui = use_ui
        self._agent = self._build_agent(use_ui)
        self._user_id = "remote_agent"
        self._runner = Runner(
            app_name=self._agent.name,
            agent=self._agent,
            artifact_service=InMemoryArtifactService(),
            session_service=InMemorySessionService(),
            memory_service=InMemoryMemoryService(),
        )

        # --- MODIFICATION: Wrap the schema ---
        # Load the A2UI_SCHEMA string into a Python object for validation
        try:
            # First, load the schema for a *single message*
            single_message_schema = json.loads(A2UI_SCHEMA)

            # The prompt instructs the LLM to return a *list* of messages.
            # Therefore, our validation schema must be an *array* of the single message schema.
            self.a2ui_schema_object = {"type": "array", "items": single_message_schema}
            logger.info(
                "A2UI_SCHEMA successfully loaded and wrapped in an array validator."
            )
        except json.JSONDecodeError as e:
            logger.error(f"CRITICAL: Failed to parse A2UI_SCHEMA: {e}")
            self.a2ui_schema_object = None
        # --- END MODIFICATION ---

    def get_processing_message(self) -> str:
        return "Designing your landscape options..."

    def _build_agent(self, use_ui: bool) -> LlmAgent:
        """Builds the LLM agent for the landscape agent."""
        LITELLM_MODEL = os.getenv("LITELLM_MODEL", "gemini-2.5-flash")

        if use_ui:
            # Construct the full prompt with UI instructions, examples, and schema
            instruction = AGENT_INSTRUCTION + get_ui_prompt(
                self.base_url, LANDSCAPE_UI_EXAMPLES
            )
        else:
            instruction = get_text_prompt()

        return LlmAgent(
            model=LiteLlm(model=LITELLM_MODEL),
            name="landscape_agent",
            description="An agent that helps design landscapes.",
            instruction=instruction,
            tools=[get_landscape_options],
        )

    async def stream(self, query, session_id, image_part=None) -> AsyncIterable[dict[str, Any]]:
        session_state = {"base_url": self.base_url}

        session = await self._runner.session_service.get_session(
            app_name=self._agent.name,
            user_id=self._user_id,
            session_id=session_id,
        )
        if session is None:
            session = await self._runner.session_service.create_session(
                app_name=self._agent.name,
                user_id=self._user_id,
                state=session_state,
                session_id=session_id,
            )
        elif "base_url" not in session.state:
            session.state["base_url"] = self.base_url

        # --- Begin: UI Validation and Retry Logic ---
        max_retries = 1  # Total 2 attempts
        attempt = 0
        current_query_text = query

        # Ensure schema was loaded
        if self.use_ui and self.a2ui_schema_object is None:
            logger.error(
                "--- LandscapeAgent.stream: A2UI_SCHEMA is not loaded. "
                "Cannot perform UI validation. ---"
            )
            yield {
                "is_task_complete": True,
                "content": (
                    "I'm sorry, I'm facing an internal configuration error with my UI components. "
                    "Please contact support."
                ),
            }
            return

        while attempt <= max_retries:
            attempt += 1
            logger.info(
                f"--- LandscapeAgent.stream: Attempt {attempt}/{max_retries + 1} "
                f"for session {session_id} ---"
            )

            parts = [types.Part.from_text(text=current_query_text)]
            if image_part:
                if image_part.bytes_data:
                    logger.info(f"Adding image bytes to message")
                    parts.append(
                        types.Part.from_bytes(
                            data=image_part.bytes_data,
                            mime_type=image_part.mime_type or "image/jpeg",
                        )
                    )
                else:
                    logger.info(f"Adding image URL to message: {image_part.url}")
                    parts.append(
                        types.Part.from_uri(
                            file_uri=image_part.url,
                            mime_type=image_part.mime_type or "image/jpeg",
                        )
                    )

            current_message = types.Content(role="user", parts=parts)
            final_response_content = None

            async for event in self._runner.run_async(
                user_id=self._user_id,
                session_id=session.id,
                new_message=current_message,
            ):
                logger.info(f"Event from runner: {event}")
                if event.is_final_response():
                    if (
                        event.content
                        and event.content.parts
                        and event.content.parts[0].text
                    ):
                        final_response_content = "\n".join(
                            [p.text for p in event.content.parts if p.text]
                        )
                    break  # Got the final response, stop consuming events
                else:
                    logger.info(f"Intermediate event: {event}")
                    # Yield intermediate updates on every attempt
                    yield {
                        "is_task_complete": False,
                        "updates": self.get_processing_message(),
                    }

            if final_response_content is None:
                logger.warning(
                    f"--- LandscapeAgent.stream: Received no final response content from runner "
                    f"(Attempt {attempt}). ---"
                )
                if attempt <= max_retries:
                    current_query_text = (
                        "I received no response. Please try again."
                        f"Please retry the original request: '{query}'"
                    )
                    continue  # Go to next retry
                else:
                    # Retries exhausted on no-response
                    final_response_content = "I'm sorry, I encountered an error and couldn't process your request."
                    # Fall through to send this as a text-only error

            is_valid = False
            error_message = ""

            if self.use_ui:
                logger.info(
                    f"--- LandscapeAgent.stream: Validating UI response (Attempt {attempt})... ---"
                )
                try:
                    if "---a2ui_JSON---" not in final_response_content:
                        raise ValueError("Delimiter '---a2ui_JSON---' not found.")

                    text_part, json_string = final_response_content.split(
                        "---a2ui_JSON---", 1
                    )

                    if not json_string.strip():
                        raise ValueError("JSON part is empty.")

                    json_string_cleaned = (
                        json_string.strip().lstrip("```json").rstrip("```").strip()
                    )

                    if not json_string_cleaned:
                        raise ValueError("Cleaned JSON string is empty.")

                    # --- New Validation Steps ---
                    # 1. Check if it's parsable JSON
                    parsed_json_data = json.loads(json_string_cleaned)

                    # 2. Check if it validates against the A2UI_SCHEMA
                    # This will raise jsonschema.exceptions.ValidationError if it fails
                    logger.info(
                        "--- LandscapeAgent.stream: Validating against A2UI_SCHEMA... ---"
                    )
                    jsonschema.validate(
                        instance=parsed_json_data, schema=self.a2ui_schema_object
                    )
                    # --- End New Validation Steps ---

                    logger.info(
                        f"--- LandscapeAgent.stream: UI JSON successfully parsed AND validated against schema. "
                        f"Validation OK (Attempt {attempt}). ---"
                    )
                    is_valid = True

                except (
                    ValueError,
                    json.JSONDecodeError,
                    jsonschema.exceptions.ValidationError,
                ) as e:
                    logger.warning(
                        f"--- LandscapeAgent.stream: A2UI validation failed: {e} (Attempt {attempt}) ---"
                    )
                    logger.warning(
                        f"--- Failed response content: {final_response_content[:500]}... ---"
                    )
                    error_message = f"Validation failed: {e}."

            else:  # Not using UI, so text is always "valid"
                is_valid = True

            if is_valid:
                logger.info(
                    f"--- LandscapeAgent.stream: Response is valid. Sending final response (Attempt {attempt}). ---"
                )
                logger.info(f"Final response: {final_response_content}")
                yield {
                    "is_task_complete": True,
                    "content": final_response_content,
                }
                return  # We're done, exit the generator

            # --- If we're here, it means validation failed ---

            if attempt <= max_retries:
                logger.warning(
                    f"--- LandscapeAgent.stream: Retrying... ({attempt}/{max_retries + 1}) ---"
                )
                # Prepare the query for the retry
                current_query_text = (
                    f"Your previous response was invalid. {error_message} "
                    "You MUST generate a valid response that strictly follows the A2UI JSON SCHEMA. "
                    "The response MUST be a JSON list of A2UI messages. "
                    "Ensure the response is split by '---a2ui_JSON---' and the JSON part is well-formed. "
                    f"Please retry the original request: '{query}'"
                )
                # Loop continues...

        # --- If we're here, it means we've exhausted retries ---
        logger.error(
            "--- LandscapeAgent.stream: Max retries exhausted. Sending text-only error. ---"
        )
        yield {
            "is_task_complete": True,
            "content": (
                "I'm sorry, I'm having trouble generating the interface for that request right now. "
                "Please try again in a moment."
            ),
        }
        # --- End: UI Validation andRetry Logic ---
