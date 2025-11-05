# A2A Dart Package

## Overview

This package provides a Dart implementation of the A2A (Agent-to-Agent) protocol. It includes a client for interacting with A2A servers and a server framework for building A2A agents.

## Client

The `A2AClient` provides a simple and convenient way to interact with an A2A server. It supports all the standard A2A RPC calls, including `get_agent_card`, `create_task`, and `execute_task`.

## Server

The `A2AServer` provides a flexible and extensible framework for building A2A agents. It is built on top of the `shelf` package and uses a request handler pipeline to process incoming requests.
