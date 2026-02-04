# API Evaluation: `packages/genui`

## Executive Summary

**Score: A-**

The `packages/genui` library demonstrates a strong adherence to generally accepted API design principles, particularly **Contract-First Design** and **Separation of Concerns**. The architecture is modular, with clear boundaries between the UI surface, the logic controller, and the transport layer.

The primary areas for improvement are in **Interface Ergonomics** (specifically the asymmetry of transport) and minor **Leaky Abstractions** (wire format details leaking into the controller).

## Analysis by Principle

### 1. Contract-First Design (A)

The library makes excellent use of abstract interfaces to define contracts.

- `GenUiContext` and `GenUiHost` clearly define the interaction surface for widgets and logic.
- `GenUiActionDelegate` allows for extensible behavior without inheritance.
- `A2uiMessageSink` cleanly decouples message processing from the source.

### 2. The KISS Mandate (B+)

Most interfaces are focused and minimal.

- **Good:** `GenUiSurface` takes only what it needs (`GenUiContext`).
- **Concern:** `GenUiConversation` has a slightly "busy" constructor, requiring manual stitching of `adapter`, `engine`, and an `onSend` callback. This increases the cognitive load for setup.

### 3. Separation of Concerns (B+)

Responsibilities are well-partitioned.

- `A2uiTransportAdapter` handles parsing separate from logic.
- `GenUiController` manages state separate from rendering.
- **Concern:** `GenUiController` is responsible for constructing `ChatMessage` objects for user actions (e.g., in `handleUiEvent`). This leaks the "wire format" concept into the controller, which should ideally be domain-centric.

### 4. Interface Ergonomics (B)

- **Predictability:** Naming is consistent (`GenUi...` prefix).
- **Asymmetry:** The handling of network traffic is asymmetric. Incoming traffic flows through `A2uiTransportAdapter`, but outgoing traffic is handled via a completely separate `onSend` callback passed to `GenUiConversation`. This lacks **Orthogonality** and makes the "Transport" concept feel incomplete.

### 5. Type Safety & Robustness (A)

- Strong typing is used effectively.
- `JsonMap` is used where dynamic behavior is inherent, but boundaries are strict.
- Error handling in `GenUiController` is robust, catching validation errors and reporting them nicely without crashing.

## Suggestions for Improvement

### 1. Unify Transport Interface (Refined)

**Issue:** The split between `A2uiTransportAdapter` (inbound) and `onSend` (outbound) works against the **Principle of Least Astonishment** and makes it hard to swap transport implementations.

**Recommendation:**
Define a `GenUiTransport` interface that unifies inbound and outbound traffic, allowing `GenUiConversation` to be initialized with a single transport dependency.
