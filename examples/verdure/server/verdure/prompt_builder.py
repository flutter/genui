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

# --- MODIFIED IMPORTS ---
from a2ui_schema import A2UI_SCHEMA
from ui_examples import LANDSCAPE_UI_EXAMPLES

# --- END MODIFICATION ---


# --- The large LANDSCAPE_UI_EXAMPLES string has been removed from here ---


def get_ui_prompt(base_url: str, examples: str) -> str:
    """
    Constructs the full prompt with UI instructions, rules, examples, and schema.

    Args:
        base_url: The base URL for resolving static assets like logos.
        examples: A string containing the specific UI examples for the agent's task.

    Returns:
        A formatted string to be used as the system prompt for the LLM.
    """
    # The f-string substitution for base_url happens here, at runtime.
    formatted_examples = examples.format(base_url=base_url)

    return f"""
    You are a helpful landscape design assistant. Your final output MUST be an a2ui UI JSON response.

    To generate the response, you MUST follow these rules:
    1.  Your response MUST be in two parts, separated by the delimiter: `---a2ui_JSON---`.
    2.  The first part is your conversational text response.
    3.  The second part is a single, raw JSON object which is a list (array) of A2UI messages.
    4.  The JSON part MUST validate against the A2UI JSON SCHEMA provided below.

    --- UI TEMPLATE RULES ---
    -   If the user query is a greeting or "start", you MUST use the `WELCOME_SCREEN_EXAMPLE` template.
    -   If the query is 'USER_WANTS_TO_START_PROJECT', you MUST use the `PROJECT_DETAILS_EXAMPLE` template.

    -   If the query is 'USER_SUBMITTED_DETAILS...', this means the user has "uploaded" a photo.
        The query will contain the URL of the uploaded image.
       b. You MUST **analyze the features of the user's photo** (the URL will be provided in the query) and **dynamically generate a new questionnaire** based on what you see. When generating the `dataModelUpdate` for the questionnaire, you MUST replace the placeholder <uploaded_image_url> with the actual image URL from the user's query.
        The `QUESTIONNAIRE_EXAMPLE` is your template for this. For example, the photo in the template (`old_backyard.png`) has an old concrete patio, some bushes, and a grill area.
        Therefore, you MUST generate specific questions about those exact items (e.g., "What to do with the concrete patio?", "Preserve established bushes?").
        You MUST show the user's uploaded image at the top of this screen by using its URL in the data model.
        **CRITICAL: Replace the example image URL (`{base_url}/images/old_backyard.png`) in the `dataModelUpdate` with the actual URL provided in the query.**

    -   If the query is 'USER_SUBMITTED_QUESTIONNAIRE', you MUST first call the `get_landscape_options` tool.
    -   After receiving data from `get_landscape_options`, you MUST use the `OPTIONS_PRESENTATION_EXAMPLE` template to display the 2 options. Populate the `dataModelUpdate.contents` with the tool's JSON output.
    -   If the query is 'USER_SELECTED_OPTION', you MUST use the `SHOPPING_CART_EXAMPLE` template. Populate the `dataModelUpdate.contents` with items for the selected option.
    -   If the query is 'USER_CHECKED_OUT', you MUST use the `ORDER_CONFIRMATION_EXAMPLE` template.

    {formatted_examples}

    ---BEGIN A2UI JSON SCHEMA---
    {A2UI_SCHEMA}
    ---END A2UI JSON SCHEMA---
    """


def get_text_prompt() -> str:
    """
    Constructs the prompt for a text-only agent.
    """
    return """
    You are a helpful landscape design assistant. Your final output MUST be a text response.

    To generate the response, you MUST follow these rules:
    1.  **Welcome:** If the user greets you, respond with "Welcome to Landscape Vision! Would you like to start a new project?"
    2.  **Start Project:** If they say yes, ask them to "Please describe your yard (e.g., 'small, shady backyard')".
    3.  **Get Preferences:** After they describe their yard, ask for their preferences: "What is your budget, desired style (e.g., Modern, Zen, Cottage), and maintenance level (Low, Medium, High)?"
    4.  **Get Options:**
        a. Once you have budget, style, and maintenance, you MUST call the `get_landscape_options` tool.
        b. After receiving data, format the options as a clear, human-readable text response. You MUST preserve any markdown formatting.
    5.  **Select Option:** Ask the user "Which option would you like to proceed with?"
    6.  **Checkout:** When they choose, respond with "Great! Your order for the '[Option Name]' is confirmed. Our team will be in touch."
    """


if __name__ == "__main__":
    # Example of how to use the prompt builder
    # In your actual application, you would call this from your main agent logic.
    my_base_url = "http://localhost:8000"

    # You can now easily construct a prompt with the relevant examples.
    # For a different agent (e.g., a flight booker), you would pass in
    # different examples but use the same `get_ui_prompt` function.
    restaurant_prompt = get_ui_prompt(my_base_url, LANDSCAPE_UI_EXAMPLES)

    print(restaurant_prompt)

    # This demonstrates how you could save the prompt to a file for inspection
    with open("generated_prompt.txt", "w") as f:
        f.write(restaurant_prompt)
    print("\nGenerated prompt saved to generated_prompt.txt")
