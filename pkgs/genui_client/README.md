# genui_client

A Flutter application that can generate user interfaces using AI.

It calls the AI to generate a JSON representation of a user interface and then
converts that JSON representation into a rendered UI. UI Events are then
propagated back to the LLM as simulated tool results (it makes the LLM think
that it called the tool "get_ui_events", and that there was a response).

# Contributing

Read our [Contributor Guide] for contributing to the Flutter repos.

[Contributor Guide]: https://github.com/flutter/flutter/blob/master/docs/contributing/README.md
