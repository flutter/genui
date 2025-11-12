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

logger = logging.getLogger(__name__)


def get_landscape_options(
    budget: str, style: str, maintenance: str, space_description: str
) -> str:
    """
    Call this tool to get landscape design options based on user preferences.
    'budget' is the user's estimated budget.
    'style' is the desired landscape vibe (e.g., 'Modern', 'Zen', 'Cottage').
    'maintenance' is the preferred level (e.g., 'Low', 'Medium', 'High').
    'space_description' is the user's text description of their yard.
    """
    logger.info("--- TOOL CALLED: get_landscape_options ---")
    logger.info(f"  - Budget: {budget}")
    logger.info(f"  - Style: {style}")
    logger.info(f"  - Maintenance: {maintenance}")
    logger.info(f"  - Space: {space_description}")

    # In a real app, this would query a model or database.
    # Here, we return hardcoded options.
    options = [
        {
            "name": "Modern Zen Garden",
            "detail": "Low maintenance, drought-tolerant plants, and clean lines. Perfect for relaxation.",
            "imageUrl": "http://localhost:10002/images/zen_garden.png",
            "price": "Est. $5,000 - $8,000",
            "time": "Est. 2-3 weeks",
            "tradeoffs": "Higher upfront cost, less floral variety.",
            "id": "option1",
        },
        {
            "name": "English Cottage Garden",
            "detail": "Vibrant, colorful, and teeming with life. A classic, romantic look.",
            "imageUrl": "http://localhost:10002/images/cottage_garden.png",
            "price": "Est. $3,000 - $6,000",
            "time": "Est. 4-6 weeks",
            "tradeoffs": "Higher maintenance (watering/weeding), seasonal changes.",
            "id": "option2",
        },
    ]

    # --- MODIFICATION ---
    # Remove the filtering logic to always return both options
    items = options
    # --- END MODIFICATION ---

    logger.info(f"  - Success: Returning {len(items)} landscape options.")
    return json.dumps(items)
