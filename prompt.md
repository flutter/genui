# UI Tools

I'd like to build a new Flutter package in pkgs/spikes/fcp_tools

This package will contain:

- An example that is a chat app that uses firebase_ai to connect to Gemini and have a discussion that is augmented by user interface "surfaces".
- The package will provide a set of AI tools that an LLM can use to manipulate the UI, and the tools will use the pkgs/spikes/fcp_client package to create the surfaces.
- The surfaces will have string IDs that the LLM can use to refer to them.

## Tools

I had another idea, along the lines of the tool idea above. I was thinking about how to do streaming, and it seems like the best way to do that is is to do this: Make a set of tools that the LLM can use to manipulate the UI:

- `manage_ui`, which can set the initial UI for a surface, get the current layout and state of the surface, and modify the layout and state of the surface UI using the JSON patches that FCP uses.
- `manage_surfaces`, which can create, list, and remove surfaces.
- `get_widget_catalog`, which returns the currently available FCP widget catalog.

Each surface is a separate FcpClient Widget with its own state, and the API allows getting the list of surface widgets.

We can provide the initial state of the UI and surfaces in the prompt.
