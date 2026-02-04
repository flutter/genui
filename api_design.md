# Foundations of Canonical API Design Principles

The following canonical API design principles are distilled from the collected knowledge of software engineering.

## I. Core Architectural Philosophy

### 1. Contract-First Design (API First)
Treat the interface definition as the primary product artifact, distinct from its implementation. Define the contract (the "what") rigorously before writing the code (the "how"). This decoupling allows consumers to validate the design against requirements before engineering resources are committed and serves as the single source of truth for the system's capabilities.

### 2. The KISS Mandate (Minimal Surface Area)
Complexity is the primary vector for defects and integration friction. Expose the smallest number of concepts necessary to solve the problem ("just enough power"). Avoid "Swiss Army knife" interfaces that perform multiple unrelated operations. If an interface requires extensive setup or explanation to use, it likely violates this principle.

### 3. YAGNI (Avoid Speculative Generality)
Do not add parameters, operations, or data fields for hypothetical future needs. Speculative features introduce "accidental complexity"—complexity arising from the solution rather than the problem. Build only what is required for current, concrete use cases to maintain a lean and testable interface.

### 4. Separation of Concerns (Information Hiding)
The API must expose capabilities, not internal state or storage models. Never leak implementation details (like database schemas or specific algorithms) through the interface. This encapsulation ensures that the internal architecture can be refactored or completely replaced without breaking consumers.

## II. Interface Ergonomics & Semantics

### 1. The Principle of Least Astonishment (Predictability)
An interface should behave exactly as a user expects based on their prior knowledge of the system. If a standard pattern exists (e.g., naming conventions, error structures), deviate from it only with significant justification. Consistency reduces the cognitive load required to learn the API.

### 2. Intent-Revealing Names
Names should describe *business intent*, not technical mechanics. A method named `publishArticle()` is superior to `updateRowStatus()`. Use specific, self-descriptive terminology (e.g., `temperatureCelsius` instead of `temp`) to prevent ambiguity and reduce the reliance on external documentation.

### 3. Command-Query Separation (CQS)
Clearly distinguish between operations that retrieve data (Queries) and operations that modify state (Commands). Queries should ideally be safe and side-effect-free, allowing consumers to call them repeatedly without risk. Mixing data retrieval with state mutation in a single operation leads to unpredictable system behavior.

### 4. Orthogonality (Composable Primitives)
Design small, independent primitives that can be composed to create complex behaviors, rather than creating rigid, complex operations for every specific scenario. Changing one independent parameter should not have unexpected side effects on unrelated parts of the request.

## III. Operational Reliability & Robustness

### 1. Idempotency (Safe Retries)
In a distributed system, network failures are inevitable. Operations that change state must be designed to be idempotent, meaning they can be safely retried multiple times without producing cumulative side effects (e.g., double-charging). This is often achieved by requiring clients to provide a unique "idempotency key" or transaction identifier.

### 2. The Robustness Principle (Postel’s Law)
**"Be conservative in what you send, be liberal in what you accept."**
Strictly adhere to the interface contract when generating output, but implement tolerance when processing input (e.g., ignoring unknown fields rather than crashing). This improves interoperability and allows the system to evolve without immediately breaking older clients.

### 3. Circuit Breaking (Fail Fast)
If a dependency or subsystem is failing, stop calling it immediately to prevent cascading failures. The interface should fail fast and return a specific error rather than hanging indefinitely. This preserves system resources and provides immediate feedback to the consumer.

### 4. Bulk & Batch Operations
To reduce network overhead and latency, provide mechanisms to process multiple items in a single request (e.g., `createItems([item1, item2])`). However, ensure the behavior of partial failures is well-defined—either the entire batch fails atomically, or the response clearly indicates the success/failure status of each individual item.

## IV. Data Handling & Evolution

### 1. Scalable Pagination (Cursor over Offset)
Never return unbounded lists of data. For large datasets, prefer **Cursor-Based (Keyset) Pagination** over Offset-Based Pagination. Cursors (pointers to a specific record) provide constant-time performance (O(1)) and data stability, whereas offsets degrade in performance (O(n)) and suffer from skipped/duplicate records when data is modified during iteration.

### 2. Evolutionary Design (Versioning)
Plan for change from day one. Interfaces will evolve, and breaking changes must be managed without disrupting existing consumers. Use explicit versioning strategies (e.g., semantic versioning) and establish a clear deprecation lifecycle (warn → sunset → remove) to give consumers time to migrate.

### 3. Type Safety & Strict Validation
Enforce constraints at the boundary. Use strong types (e.g., Enums instead of raw strings, distinct types for monetary values) to make invalid states unrepresentable. Validate all input rigorously before processing to prevent data corruption and security vulnerabilities.

### 4. Structured Error Reporting
Errors must be machine-readable and actionable. Return specific error codes (not just generic failure indicators) accompanied by descriptive messages and, where possible, structured metadata that allows the consumer to programmatically recover or correct their input.

### 5. Single Source of Truth (DRY Data)
Avoid defining the same business logic or data structure in multiple places. Ensure that a concept (e.g., a "User" or "Order") has a canonical representation. Divergent definitions lead to integration errors where one part of the system enforces rules that another ignores.