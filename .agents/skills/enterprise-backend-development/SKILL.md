---
name: enterprise-backend-development
description: >
  Comprehensive, language-agnostic playbook for building enterprise-grade and SaaS
  backends. Use this skill for ANY backend task: designing services, wiring dependencies,
  configuration & environment separation, cross-cutting concerns (logging/auditing/tracing/
  security), persistence & transactions, concurrency & isolation, API contracts (DTOs,
  validation, versioning, error models), authentication/authorization (JWT/OAuth2/RBAC),
  multi-tenancy & tenant isolation, messaging & event-driven systems, idempotency &
  resilience (retry/circuit-breaker/timeout/DLQ/outbox/SAGA), observability (metrics/logs/
  traces), caching, async & scheduled work, the testing pyramid (70% unit / 20% integration /
  10% e2e), CI/CD, containerization & Kubernetes, Infrastructure-as-Code, and optional AI
  augmentation. Applies to every stack — Java/Spring, .NET, Node.js/NestJS, Python/Django/
  FastAPI, Go, etc. The principles are framework-independent; framework features are only
  the local implementation of these patterns.
---

# Enterprise Backend Development — Master Skill

> **What "enterprise" means here:** Enterprise software is defined by *how it behaves*, not
> *what it does*. Its design is driven by **Non-Functional Requirements (NFRs)** —
> scalability, reliability, security, maintainability, performance, availability, compliance,
> and observability. If NFRs dominate the design decisions, it is enterprise software.
>
> **Golden rule of this skill:** Every concept below is an **architectural pattern**, not a
> language feature. `IoC`, `DI`, scopes, lifecycle, transactions, isolation, AOP/middleware,
> messaging, multi-tenancy, observability — all exist in every serious stack. A framework
> (Spring Boot, ASP.NET Core, NestJS, Django, FastAPI, Go + libraries) just provides the most
> automated *implementation*. Implement the **pattern**, then use whatever your chosen
> language gives you.

---

## 0. How the agent should use this skill

When given any backend task, work in this order and **do not skip steps**:

1. **Classify the work against NFRs.** Ask which of {scalability, reliability, security,
   maintainability, performance, availability, compliance, observability} are in play. The
   answers decide the architecture, not personal preference.
2. **Identify the language/stack** for the project (Node, Java/Spring, .NET, Python, Go…).
   Keep all guidance below but express it with that stack's idioms. Never hard-code Java/.NET.
3. **Map the request to the relevant sections** (e.g. "build an orders endpoint" → §3 layering,
   §4 DI, §7 transactions, §9 API contracts, §10 security, §11 multi-tenancy if SaaS, §14
   observability, §17 testing).
4. **Apply the patterns even when the current project "doesn't need them yet"** if the task is
   to produce reusable scaffolding: include the *hooks* for messaging, multi-tenancy and
   idempotency so they can be turned on later (see §11, §12, §13). Do not bloat a tiny script,
   but for any service that will live in production, wire the seams.
5. **Finish with the relevant checklist in §22** before declaring done.

**Stack-translation table (memorize the mapping, then use the right one):**

| Pattern | Java / Spring | .NET / ASP.NET Core | Node.js / NestJS | Python | Go |
|---|---|---|---|---|---|
| DI container | ApplicationContext | built-in DI / `IServiceProvider` | Nest IoC / `@Injectable` | `dependency-injector`, FastAPI `Depends` | manual / `wire`, `fx` |
| Web entry | `@RestController` | `[ApiController]` | `@Controller` | FastAPI router / Django view | `net/http`, gin, echo |
| Config binding | `@ConfigurationProperties` | `IOptions<T>` | `ConfigModule` | pydantic `Settings` | `viper`, env structs |
| Cross-cutting | Spring AOP (proxies) | middleware + filters | interceptors / middleware | middleware / decorators | middleware funcs |
| Transactions | `@Transactional` | `TransactionScope`/EF | TypeORM transactions | SQLAlchemy session | `database/sql` Tx |
| ORM | JPA/Hibernate | EF Core | TypeORM/Prisma | SQLAlchemy/Django ORM | `sqlc`, `gorm` |
| Validation | Bean Validation | Data Annotations | class-validator | pydantic | validator tags |
| Metrics | Micrometer | `System.Diagnostics.Metrics` | prom-client | prometheus_client | prometheus client |
| Messaging | spring-kafka / amqp | MassTransit/Confluent | kafkajs/amqplib | aiokafka/pika | sarama / amqp |

---

## 1. Enterprise mindset & Non-Functional Requirements

### 1.1 What makes software "enterprise"
Built to operate at organizational scale: many users, teams and departments; integration-heavy;
supports critical business operations; long-lived; must survive change, failures and growth.

**Typical characteristics to design for from day one:**
multiple users & roles · shared database · concurrent access · long lifetime · frequent change ·
integration with other systems · monitoring & logging · security & auditability.

### 1.2 The NFRs that drive every decision
- **Scalability** — handle more load (prefer horizontal scaling over vertical).
- **Reliability** — correct results under failure; e.g. *99.99% reliable per 24h*.
- **Security** — authentication, authorization, auditability, data isolation.
- **Maintainability** — large codebases + many teams + long life ⇒ low coupling required.
- **Performance** — e.g. *95% of operations ≤ 3 seconds*.
- **Availability** — e.g. *99.99% uptime per 24h*; design for failure.
- **Compliance** — provable "who did what, when, why".
- **Observability** — measurable, debuggable, traceable in production.

### 1.3 Requirements: business vs technical
- **Business / functional requirements** = rules, workflows, roles. Captured as
  **features → user stories** ("As a customer, I want to … so that …").
- **Technical / non-functional requirements** = scalability, security, performance,
  availability expressed as measurable targets (see the percentages above).

### 1.4 Why architecture matters
It manages complexity, enables scalability, supports change, and reduces risk. Architecture =
the long-term *structural* decisions; design = the detailed decisions inside that structure.
Design principles operate mostly at detailed-design & implementation, but they influence
architectural decisions too.

### 1.5 SaaS & enterprise relationship
SaaS = software delivered over the internet as a service (no local install, no server
management by the user, subscription/usage billing). SaaS systems are almost always
enterprise-grade: highly scalable, **multi-tenant**, secure, highly available, strong
architecture. Multi-tenancy (many customer organizations on one system with isolated data) is
the defining SaaS challenge — see §11.

---

## 2. Architecture styles & design principles

### 2.1 Design principles (apply in every language)
- **Separation of Concerns (SoC)** — each module owns one concern; configuration is not
  business logic; web mechanics are not business decisions.
- **Single Responsibility (SRP)** — one reason to change per unit.
- **Open/Closed (OCP)** — extend behavior by adding code, not editing existing code. DI makes
  this practical: add a new implementation, switch by configuration.
- **Liskov Substitution (LSP)** — subtypes must be usable wherever the base type is expected.
- **Interface Segregation (ISP)** — many small, client-specific interfaces beat one fat
  interface (so changing one tenant's feature doesn't disrupt others).
- **Dependency Inversion (DIP)** — depend on abstractions, not concretions.
- **DRY** — don't repeat knowledge; centralize policy (see AOP/middleware in §6).

**Design patterns** = reusable solutions to recurring problems. **Avoid pattern misuse /
over-engineering** — use a pattern only when the problem is actually present.

### 2.2 Architecture styles (pick deliberately)
- **Monolithic** — single deployment. Easy to start, hard to scale. Risks: full redeploy ⇒
  downtime; in-memory state lost on deploy; one module's bug can sink the whole system; tight
  coupling ⇒ poor resource use and high latency.
- **Layered** — Presentation → Application → Domain → Infrastructure. The default backend
  shape (see §3).
- **Microservices** — independently deployable services, each in its own process, communicating
  over network (HTTP/messaging), often each owning its own database. Optimizes deployment
  independence, scalability, operational separation.
- **Domain-Driven (DDD)** — business-first design with **bounded contexts**; organize by
  business capability; loose coupling between domains; clear data ownership. Works inside a
  monolith, a modular monolith, or microservices — it is an organizing principle, not a
  deployment style.
- **Stateless services** — no in-memory session state ⇒ cloud-friendly, horizontally scalable.
- **Event-driven** — components emit/consume asynchronous events through a bus/broker; loose
  coupling. See §12.

### 2.3 Cloud-native vs traditional mindset
Traditional: static servers, manual & vertical scaling, snowflake servers, rare deploys.
Cloud-native: dynamic infrastructure, horizontal scaling, automated provisioning, **failure
expected**, continuous deployment. Cloud-native assumes *servers are disposable and
infrastructure is programmable*. Cloud-native is **not** merely "hosting on a VM", "using cloud
storage", "using microservices", or "using containers" — it is the full set of properties:
runs in containers, scales horizontally, is resilient, is observable.

---

## 3. Project structure & layering

Use a layered request flow in any stack:

```
Client → Controller/Handler → Service (business logic) → Repository/DAO → ORM → Database
```

- **Controller / handler layer** — *web mechanics only*: routing, parse/serialize, trigger
  input validation, map HTTP status codes, delegate to a service. **Thin controller**: makes
  ZERO business decisions, runs NO repository queries, does NO transaction management, NO
  password hashing. Allowed: routing, parameter extraction, `@Valid`-style validation
  triggering, delegation, returning status codes.
- **Service layer** — business logic, **transaction boundaries** (§7), business-rule
  validation (§9), orchestration across repositories, tenant-aware logic.
- **Repository / DAO layer** — database access; per-query concerns like locking (§8) live here.
- **ORM layer** — object↔table mapping.
- **Database** — persistent store.

**Recommended package/folder layout (organize by feature, then by layer):**
```
src/<feature>/
  controller/    # or handler/route layer
  service/
  repository/    # or dao/
  entity/        # or model/ (persistence types — never exposed)
  dto/           # request DTOs + response DTOs (the API contract)
  mapper/        # entity <-> dto mapping
  exception/     # domain exceptions + global handler
  config/        # configuration, security config, etc.
  messaging/     # producers/consumers/event contracts (even if empty initially)
```

**Typical implementation sequence:** entity → repository → request DTO → response DTO →
service (validate → map → persist → map) → controller (accept DTO, `@Valid`, delegate, return
DTO) → global exception handling (validation errors, duplicates, not-found, stable error model).

---

## 4. Dependency Injection & Inversion of Control

### 4.1 The pattern (not the framework)
- **Dependency** = an object a class needs to function (e.g. `OrderService` depends on
  `PaymentService`).
- **Tight coupling** (bad): the class `new`s its own dependency. It controls creation, cannot
  swap implementations, is hard to test/mock/extend.
- **Dependency Injection** (good): dependencies are *provided externally*. The class depends
  only on an abstraction; the container supplies the instance.
- **Inversion of Control (IoC)**: control over object creation & wiring moves *out of your
  code* into a container/runtime that creates objects, injects dependencies, applies
  cross-cutting proxies, manages lifecycle, and destroys objects.

### 4.2 Why DI is critical for enterprise/SaaS
Decoupling (depend on abstractions) · testability (inject mocks) · flexibility (swap
implementations without editing the consumer — this is OCP) · maintainability under constant
change · **per-tenant runtime behavior selection** (DI lets you choose behavior per tenant
instead of hard-coding it). Without DI there is no scalable SaaS architecture, and manual
wiring becomes impossible at the scale of hundreds of classes, multiple layers and many
integrations.

### 4.3 Worked pattern (language-neutral)
```
// 1) Abstraction (contract)
interface PaymentService { pay(amountCents) }

// 2) Implementations
class StripePaymentService implements PaymentService { pay(c){...} }
class PayPalPaymentService implements PaymentService { pay(c){...} }

// 3) Consumer depends ONLY on the abstraction, via constructor injection
class OrderService {
  constructor(private payment: PaymentService) {}   // injected
  placeOrder(c){ this.payment.pay(c) }
}
```
Switching Stripe → PayPal changes **only configuration**, never `OrderService`.

### 4.4 Selecting implementations
- **Primary/default marker** (Spring `@Primary`, etc.) — simplest.
- **Configuration-driven selection** (conditional on a property/env var) — enterprise-preferred,
  e.g. `payment.provider=stripe|paypal`, switch with no code change. This is feature-flag /
  conditional wiring; mirror it with `@ConditionalOnProperty` (Spring), `IConfiguration`
  branching (.NET), provider tokens (Nest), factory functions (Go/Python).

### 4.5 Injection types
- **Constructor injection — RECOMMENDED.** Enforces immutability (final/readonly), makes
  dependencies required at creation time, prevents partially-constructed objects, gives a clear
  contract, fails fast, and is trivially testable.
- **Setter injection** — only for genuinely optional/runtime-swappable dependencies.
- **Field injection — AVOID.** Hidden dependencies, cannot be `final`/readonly, harder to test,
  breaks immutability, invisible in the constructor.

### 4.6 Scopes (lifetime of a managed object)
- **Singleton** (default) — one instance per container. Correct for **stateless, thread-safe,
  shared** services; creating thousands of service objects wastes memory.
- **Prototype / transient** — new instance each request from the container; container does NOT
  manage destruction for these.
- **Request scope** (web) — one instance per HTTP request (e.g. request metadata / request id).
- **Session scope** (web) — one instance per user session (e.g. a shopping cart).

**Critical bug to prevent:** never store client/request-specific mutable state in a singleton
(it is shared across all threads/users → catastrophic cross-request/cross-tenant data
corruption). Putting a request- or session-scoped dependency into a singleton is a design smell.

### 4.7 Lifecycle hooks & graceful resource control
- **Post-construct hook** — runs *after* dependencies are injected; do real initialization here
  (open connection pools, start consumers), **not** in the constructor (which runs before
  injection completes).
- **Pre-destroy hook** — runs at shutdown; release resources, stop background threads, flush.
  Without it: thread leaks, unclean shutdown, possible data loss. Enterprise systems must shut
  down **gracefully** (see §19 graceful shutdown).
- Scope affects timing: singleton init/destroy at startup/shutdown; request scope per request;
  prototype gets init each time but **no automatic destroy**.

### 4.8 Common DI failures
- **Missing bean / unregistered dependency** — nothing of the required type is registered.
- **Circular dependency** — A needs B and B needs A at creation time ⇒ deadlock/error.
  **Fixes, in order of preference:** (1) refactor to remove the cycle — extract a third
  collaborator both depend on; (2) lazy injection (inject a proxy resolved later) when refactor
  is hard; (3) decouple with **events** (A publishes, B listens) so there is no direct
  dependency chain.
- **Wrong scope**, **multiple-bean conflicts**, **stateful singletons** — all surfaced early by
  constructor injection, which is why it is preferred.

### 4.9 Auto-configuration / convention over configuration
Frameworks reduce enterprise complexity by detecting what is present and wiring sensible
defaults: *if library X is on the classpath → configure related components; if the user didn't
define a component → provide a default; if a feature flag/property is set → enable it.* Mirror
with conditional registration in any stack. Always allow manual override of defaults.

---

## 5. Configuration & environment separation (12-Factor)

> **Mantra:** *Build once, deploy the same artifact everywhere; change behavior via
> configuration, not code.* Configuration is **operational risk** — treat it like code:
> review, validate, version, document. A large share of production outages are configuration
> mistakes (wrong DB host/credentials, wrong cache TTL, wrong OAuth redirect URIs, a feature
> flag enabled globally by accident, DEBUG logging left on in prod).

### 5.1 What MUST be configuration (never hard-coded)
- **Infrastructure**: DB URL/username/password, cache host, message broker addresses, external
  API base URLs, SMTP server, OAuth issuer URL, token/signing secrets, object-storage bucket.
- **Environment-dependent behavior**: logging level, feature toggles, cache TTL, rate limits,
  timeout values.
- **Operational tuning**: connection-pool size, thread-pool size, retry count, timeouts,
  circuit-breaker thresholds.
- **Deployment identity**: app name, active profile/environment label, region.

### 5.2 The Twelve-Factor App (apply all twelve)
1 codebase in version control · 2 explicit isolated dependencies · 3 **config in the
environment** · 4 backing services as attached resources · 5 strict build/release/run
separation · 6 stateless processes · 7 port binding · 8 concurrency via the process model ·
9 disposability (fast startup, graceful shutdown) · 10 dev/prod parity · 11 logs as event
streams · 12 admin tasks as one-off processes.

### 5.3 Principles
- **Separation of concerns** — config is not business logic. Bad: VAT rate / discount flags
  hard-coded inside a discount method. Good: a typed config object injected into the service.
- **Twelve-Factor** — store config in the environment; secrets come from env vars / secret
  managers, never the repo.
- **Immutable artifact** — one JAR/binary/image; the environment decides behavior via env vars.
- **Environment separation** — dev/test/QA/stage/prod configs must never mix.

### 5.4 Typed configuration over scattered strings
Prefer **typed, structured, validated** config binding (Spring `@ConfigurationProperties`,
.NET `IOptions<T>`, pydantic `Settings`, Node config schema, Go env structs) over scattered
single-value injections. Reasons: centralized, testable, type-safe, validatable early.

### 5.5 Profiles / environments
Provide per-environment files/overrides (`dev`, `test`, `qa`, `stage`, `prod`). Base file holds
safe defaults; profile files override. Secrets in prod come from env vars, not files. Activate
via env var (best for containers/CI/CD) or CLI/system property. Optionally add a **safety gate**
that refuses to start on an invalid profile mix (e.g. `prod` + `dev` together).

### 5.6 Configuration resolution order (highest wins)
`command-line args > system properties > OS environment variables > profile-specific files >
base config file > code defaults`. So you can override safely at deploy time without editing
files. (Quiz pattern: an env var `APP_NAME=EnvApp` is overridden by a system property
`-Dapp.name=SystemApp`, which is overridden by a CLI arg.)

### 5.7 Fail fast — validate config at startup
Validate required/typed config on boot (bean validation / pydantic / options validation):
e.g. `issuer` must be non-blank, `tokenTtlSeconds` ≥ 60. Bad config should fail at **startup**,
not silently in production.

---

## 6. Cross-cutting concerns — AOP, middleware, interceptors

> Cross-cutting concerns apply across many features/modules: **logging, auditing, tracing,
> security/authorization, transactions, metrics, rate limiting**. Don't scatter boilerplate
> ("just add logs everywhere") — that causes repetition, inconsistent formats, missing fields
> (userId/correlationId), human error on rare paths, noise without structure, and **compliance
> risk** (an incomplete audit trail cannot prove what happened).

### 6.1 Two enforcement boundaries (use both)
- **Request/system boundary** = middleware / filters (ASP.NET middleware, Express/Nest
  middleware, servlet filters). Best for per-HTTP-request concerns: correlation-ID injection,
  request logging, authentication/authorization gate, rate limiting, CORS/CSRF. *Middleware
  ensures system-level integrity.*
- **Method/business boundary** = AOP / interceptors / decorators around service methods. Best
  for business-level policy: method-level logging, **auditing of sensitive actions**, method
  security, declarative transactions, business metrics. *AOP enforces business-level policy.*

Serious systems use **layered enforcement**: middleware protects the boundary; AOP protects
business operations. Auditing provides legal defensibility; cross-cutting enforcement reduces
human error.

### 6.2 Logging vs Auditing (not the same)
- **Logging** = operational visibility for debugging/ops (transient).
- **Auditing** = immutable, legally-defensible record of sensitive actions
  (create/approve/disable) — append-only table / event bus / immutable log.

### 6.3 AOP vocabulary (works in any AOP/interceptor system)
- **Join point** — a place you can intercept (a method execution).
- **Pointcut** — the rule selecting which join points match (e.g. "methods annotated
  `@Audited`").
- **Advice** — the code that runs at matched join points (before / after / around).
- **Aspect** — the module holding pointcuts + advice (logging aspect, auditing aspect).
- **Weaving** — attaching advice to targets (Spring uses **runtime proxies**).

### 6.4 The proxy boundary & self-invocation trap (critical)
Interception runs **only when a call crosses the proxy/interceptor boundary**. An *internal*
call (`this.otherMethod()`) bypasses the proxy ⇒ **silent policy failure**: missing
logs/audits/security/transaction. **Fix:** move the intercepted method to a *separate* injected
component and call it across the bean boundary so the proxy applies. This same trap affects
declarative transactions (§7) and method security (§10) in every proxy-based framework — and in
Node/Python decorator systems, watch for the equivalent (calling the undecorated inner function).

### 6.5 Pattern: declarative cross-cutting via metadata
Declare *intent* with annotations/decorators/attributes (`@Loggable`, `@Audited(action=...)`),
let an aspect/interceptor read the metadata and run the policy, keeping business methods clean.
In stacks without annotations, use middleware + a registry, or higher-order wrappers.

---

## 7. Persistence, transactions & ACID

### 7.1 The data access stack (any language)
- **Low-level driver** (JDBC, ADO.NET, pg/mysql clients, database/sql) — raw SQL, manual
  connection & transaction handling, lots of boilerplate, manual row→object mapping.
- **ORM specification + implementation** (JPA + Hibernate, EF Core, TypeORM/Prisma, SQLAlchemy,
  GORM) — maps objects↔tables, generates SQL, manages the unit of work. The ORM uses the driver
  internally.
- **Repository abstraction** — CRUD/derived queries without hand-writing SQL.

Entities/models map a class to a table; each instance is a row. Keep entities **internal** —
never expose them across the API boundary (§9).

### 7.2 What a transaction is
A sequence of operations executed as a **single, indivisible unit**. **Golden rule:** all
operations succeed, or all fail together. Lifecycle: *begin → execute operations →
commit (success) | rollback (failure)*. Database operations are not final until commit; a
successful `save()` disappears on rollback.

Why it matters: enterprise systems handle critical, high-stakes data (payments, orders,
inventory). A partial completion on crash = financial loss. Example workflow that must be atomic:
create order → decrease inventory → charge payment → generate invoice.

### 7.3 Declarative transactions & boundaries
Prefer **declarative** transactions (Spring `@Transactional`, .NET `TransactionScope`/EF,
SQLAlchemy/TypeORM transaction wrappers) over hand-written begin/commit/rollback. The framework
wraps the method: `begin; try { work(); commit(); } catch(e){ rollback(); }`. **Define
transaction boundaries at the service layer**, because the service encapsulates the full
business workflow. (Reminder: proxy-based `@Transactional` is bypassed by self-invocation —
§6.4.)

### 7.4 ACID
- **Atomicity** — all-or-nothing (money transfer: debit A *and* credit B, or neither).
- **Consistency** — data stays valid against all constraints (inventory never negative).
- **Isolation** — concurrent transactions must not incorrectly affect each other; behave as if
  run alone.
- **Durability** — committed data survives crashes.

In SaaS, tenants share infrastructure/DB, so strict transaction boundaries + isolation are what
prevent one tenant's failure or concurrent process from corrupting another tenant's data.

---

## 8. Concurrency, isolation & locking

### 8.1 The concurrency anomalies
- **Dirty read** — reading another transaction's *uncommitted* data; if it rolls back you used
  data that never existed.
- **Non-repeatable read** — reading the same row twice yields different values because another
  transaction modified it in between.
- **Phantom read** — re-running the same query returns a different *set of rows* because another
  transaction inserted/deleted in between.
- **Lost update** — two transactions read the same value, both modify it, the last write
  overwrites the other (e.g. inventory = 5, two buyers both read 5, both write 4, should be 3).

### 8.2 Isolation levels & the threat matrix
Higher isolation = stronger correctness but lower concurrency/performance.

| Isolation level | Dirty read | Non-repeatable read | Phantom read |
|---|---|---|---|
| READ_UNCOMMITTED | possible | possible | possible |
| READ_COMMITTED | prevented | possible | possible |
| REPEATABLE_READ | prevented | prevented | possible |
| SERIALIZABLE | prevented | prevented | prevented |

- Use **READ_COMMITTED** (or stronger) to stop dirty reads.
- Use **REPEATABLE_READ** to stop non-repeatable reads.
- Use **SERIALIZABLE** to stop phantom reads (forces sequential-like behavior; biggest perf hit).
- **Database defaults differ**: MySQL = REPEATABLE_READ; PostgreSQL / SQL Server / Oracle =
  READ_COMMITTED. Set the level explicitly when correctness depends on it. Isolation belongs at
  the **transaction/service** boundary.

### 8.3 Locking (prefer over SERIALIZABLE for lost updates)
- **Optimistic locking** — detect conflicts via a **version column** (`@Version`/`version`
  field). On conflicting update, the second commit fails and you retry. Best when conflicts are
  rare; high throughput. *Detects* conflicts.
- **Pessimistic locking** — lock rows early (`SELECT … FOR UPDATE` / `LockModeType.
  PESSIMISTIC_WRITE`); others wait until released. Best for critical sections like stock
  deduction; reduces throughput. *Prevents* conflicts. Locking is a **per-query** concern — it
  belongs in the **repository** layer (isolation belongs in the service layer).
- Expect to add **retry logic / exception handling** around optimistic-lock conflicts.

---

## 9. API contracts: DTOs, validation, versioning, error models

> **An API is a contract, not controller code.** The contract includes routes & HTTP methods,
> request schema, response schema, validation rules, error schema, and version policy. The
> *implementation* (controllers, services, repositories, DB schema, domain model) may evolve
> freely, but the exposed contract must stay stable or be versioned explicitly. Exposing
> persistence entities directly is dangerous because it couples the API to persistence design —
> a DB-field rename can crash mobile apps (JSON parse errors), break frontend validation, flood
> partner-integration tickets, and fail test suites even though business logic is unchanged.

### 9.1 DTOs (Data Transfer Objects)
A DTO is a boundary object that transfers only the fields the client needs. **Separate request
DTOs from response DTOs.** Request DTOs carry input validation; neither contains business logic.
DTOs **shield** the internal entity model: API schema is explicit/intentional, internal model
is safe to evolve, no leaking of sensitive/internal fields, no lazy-loading/serialization
surprises, easier to validate/document/version/test. Use immutable data carriers
(Java records, C# records, TypeScript readonly types, Python dataclasses/pydantic, Go structs).
Use DTOs for essentially all structured endpoints (request bodies, structured GET responses,
public/shared APIs, **error responses**). Optional only for trivial endpoints like `/health`.

For large systems use a dedicated **mapper** layer (e.g. MapStruct-style) rather than manual
mapping.

### 9.2 The three validation layers (the validation funnel)
1. **Syntactic / structural** — required fields, email format, min/max length, regex. Enforced
   with declarative validation on the request DTO at the API boundary.
2. **Semantic / business** — "email must be unique", "course capacity not exceeded", "account
   state allows action", "date range valid". Enforced in the **service layer** with repository
   access. *Does this data make sense in our business state?*
3. **Cross-field / custom** — `startDate < endDate`, "either A or B required", "password matches
   confirmation". Use custom validators that see the whole object when field-level annotations
   aren't enough.

### 9.3 Stable, machine-readable error contracts
Error responses are part of the API and must be **consistent across all endpoints**. Recommended
shape:
```json
{
  "timestamp": "2026-03-23T14:05:11Z",
  "status": 400,
  "error": "Validation Failed",
  "code": "USR_001",
  "message": "Request contains invalid fields",
  "path": "/api/v1/users",
  "traceId": "e8a0d2a3-...",
  "details": [
    { "field": "email", "message": "email must be valid" },
    { "field": "password", "message": "password must be at least 8 chars" }
  ]
}
```
- **`code`** → stable machine-readable identifier so frontends switch logic without depending on
  localized text.
- **`details[]`** → field-level UI messages mapped to form fields.
- **`traceId`** → connects the client error to distributed server logs (§14).
- Never leak stack traces or DB structure. Centralize mapping with a **global exception handler**
  (Spring `@RestControllerAdvice`, ASP.NET exception middleware / ProblemDetails, Nest exception
  filters, FastAPI exception handlers, Go error middleware).

### 9.4 Versioning — evolve without breaking clients
Strategies: **URI versioning** (`/api/v1/users`) — clearest starting point; **header/media-type
versioning** (`Accept: application/vnd.myapp.v2+json`); **query-param versioning**
(`/users?version=2`). A new version is required when you rename/remove fields, change semantics,
change required request shape, or change an error schema clients depend on. **Safe evolution:**
add optional fields, keep old fields temporarily, deprecate clearly, publish migration notes,
sunset old versions intentionally. (Some stacks support "v2+" mappings that handle v2 and all
future versions until a higher version overrides.)

### 9.5 Common API mistakes to avoid
Returning entities directly · business logic + repository calls in controllers · treating
validation as annotations only (forgetting service rules) · inconsistent error JSON · breaking
fields without versioning · vague human-only error text with no code · skipping `Location`
header + `201 Created` on resource creation.

### 9.6 API review checklist
Are entities exposed? · Are validation errors stable? · Is there a versioned base path? · Is
business logic inside controllers? · Can the frontend rely on the response/error shape?

---

## 10. Security: authentication, authorization, JWT/OAuth2, RBAC

### 10.1 AuthN vs AuthZ
- **Authentication** = *who are you?* (verify credentials, issue a token).
- **Authorization** = *what can you do?* (roles/permissions decide access).

### 10.2 Stateless security with tokens
Traditional server sessions don't scale horizontally. Modern APIs use **stateless tokens**:
user logs in → identity provider (Keycloak/Azure AD/Auth0/Cognito) issues a token → client sends
`Authorization: Bearer <token>` on each request → the security layer validates it → builds a
per-request security context → authorization (RBAC) check → business logic.

- **JWT** = JSON Web Token: `header.payload.signature`, each part Base64URL-encoded. Header +
  payload are **only encoded, not encrypted** — *never store secrets in the payload*. Only the
  signature guarantees integrity. Tokens must be short-lived, sent over HTTPS, protected from
  leaks. Typical claims: `userId`, `tenant`, `role`, `exp`.
- **JWT is just the token format.** In enterprise systems prefer **OAuth2 / OpenID Connect** for
  authentication, with JWT as the access-token format validated by services (and/or the gateway
  in zero-trust).

### 10.3 The security filter chain
Requests pass an ordered chain of filters *before* reaching controllers: CORS → JWT extraction →
authentication → authorization. Typical filter tasks: extract token, validate it, build the
authenticated context, apply security rules. Only requests passing all checks proceed.

- **Per-request security context** holds the current authenticated principal + authorities; it
  is typically stored in a thread-local-style holder so any code on the request thread can read
  the current user without passing it around. Build it by: extract token → validate → read
  username/roles → create an authentication object → store it in the per-request context holder.
- **CSRF**: relies on browsers auto-sending auth cookies. REST APIs using bearer tokens require
  an explicit `Authorization` header that a malicious site cannot forge, so CSRF protection is
  usually **disabled** for token-based APIs (keep it for cookie/session flows).

### 10.4 Role-Based Access Control (RBAC)
- **Request-level RBAC** protects URLs/routes (e.g. `/api/admin/**` requires `ADMIN`;
  `/api/public/**` is open; everything else requires authentication).
- **Method-level RBAC** protects business methods close to the logic (declarative checks like
  `@PreAuthorize("hasRole('ADMIN')")` / `hasAnyRole('ADMIN','MANAGER')`; enable method security
  explicitly). Use **both** in enterprise apps. (Method-level RBAC is proxy-based — mind §6.4.)

### 10.5 Practical security rules
Hash passwords (bcrypt/argon2) in the service, never the controller. Validate & sanitize all
input at the boundary (§9). Use HTTPS everywhere. Centralize secrets (env vars / secret
managers). Prefer the platform's vetted security library over hand-rolled crypto.

---

## 11. Multi-tenancy & tenant isolation

> **Always include this section's hooks in any SaaS-bound service even if multi-tenancy is not
> enabled yet** — retrofitting tenant isolation later is dangerous. The classic breach: a shared
> `projects` table, a user from Company A calls `GET /projects` and the response includes Company
> B's rows because the query was not tenant-filtered. *Tenant A must never see Tenant B's data.*

### 11.1 A tenant
A tenant is a customer organization using the SaaS system. Many tenants share one application;
data must be isolated.

### 11.2 Multi-tenancy architecture models
| Model | Structure | Isolation | Trade-off |
|---|---|---|---|
| **Database per tenant** | separate DB per tenant | High | strongest isolation; expensive & complex |
| **Schema per tenant** | one DB, separate schema per tenant | Medium | moderate; operationally complex |
| **Shared DB + tenant column** | one DB, one schema, `tenant_id` on every table | Low (app-enforced) | cheapest/simplest; app MUST filter by `tenant_id` |

**Key truth:** multi-tenancy is mostly an *application-design* problem, not a DB feature. The DB
only provides schemas/databases/tables; **your application enforces** tenant isolation, tenant
routing and security.

### 11.3 Implementation patterns
1. **Application-level (tenant context)** — extract `tenantId` from the validated token, store
   it in a per-request context (thread-local style), and filter every query by it. Widely used in
   SaaS microservices.
2. **Database-level** — database-per-tenant or schema-per-tenant with the ORM switching
   schema/connection per tenant via a "current tenant resolver" the ORM calls before queries.
3. **Row-level** — a `tenant_id` column in every table; every query filters by `tenant_id`.

### 11.4 The tenant-context mechanism (any language)
```
// per-request store (thread-local / async-local / context object)
class TenantContext {
  static set(id) {...}; static get() {...}; static clear() {...}
}
// a request filter/middleware reads tenant (from token claim or header) and sets it:
tenant = request.claim("tenant")   // PREFER token claim over client-supplied header
TenantContext.set(tenant)
try { next() } finally { TenantContext.clear() }   // ALWAYS clear to avoid leakage
// repositories/services read TenantContext.get() and scope queries:
repository.findByTenantId(TenantContext.get())
```
Keep **SecurityContext** (who the user is) and **TenantContext** (which tenant) as *separate*
concerns; together they yield "Alice from tenantA", so a query becomes `SELECT … WHERE
tenant_id = 'tenantA'`.

### 11.5 Thread-local / context propagation caveat
Thread-local tenant values belong to one thread. When work moves to another thread (async tasks,
worker pools), the context is **lost** (tenantId becomes null). Solutions: pass `tenantId`
explicitly, propagate context to worker threads, or include `tenantId` in async messages/events.
(Use async-local/context-aware equivalents in Node/Python; pass `context.Context` in Go.)

### 11.6 Tenant-security rule (must-test)
The tenant must come from the **trusted token**, never from client input:
```
// WRONG: service.createOrder(request.getTenantId(), ...)
// RIGHT: tenantId = securityContext.getTenantId(); service.createOrder(tenantId, ...)
```
Tests must prove: tenant A cannot read tenant B's records; tenant-scoped queries return only own
rows; the token's tenant overrides any client-supplied tenant.

---

## 12. Messaging & event-driven architecture

> **Always document and scaffold messaging seams even if the current project is synchronous**,
> so a broker can be introduced without rework. Synchronous chains (Order → Payment → Inventory →
> Email) cause blocking calls, tight coupling, cascading failures, scattered retry logic, and no
> audit trail; if the email service is slow/down the whole request slows or fails and the user
> waits for non-critical work.

### 12.1 Event-driven architecture
Publish **events** instead of making direct calls; consumers react asynchronously; producers are
decoupled from consumers. New flow: Order Service publishes `OrderCreated` → broker routes it →
Payment, Inventory, Email consume independently.

### 12.2 Messaging basics
- **Producer / consumer**, **broker** (RabbitMQ, Kafka), **delivery guarantees**
  (at-least-once, at-most-once; design consumers for at-least-once → idempotency, §12.5).
- **Queue vs Topic**:
  - *Queue* — one consumer receives each message (FIFO); competing consumers.
  - *Topic* — many subscribers each receive the message; fan-out for independent services
    (pub/sub); non-competing consumers.
- **RabbitMQ vs Kafka**: both can simulate both patterns, but RabbitMQ is **queue-first**
  (message → exchange → routed to queues → consumed once → gone), Kafka is **pub/sub-first**
  (message → topic → stored in a log for a retention window → consumers can read later, replay,
  and process independently).

### 12.3 Event vs Command
- **Command** = intent to do something (`CreateOrder`).
- **Event** = a fact that something happened (`OrderCreated`).
- Prefer **events** for decoupling.

### 12.4 Messaging vs Event-driven (core distinction)
- **Messaging = how services communicate (the transport mechanism)** — often point-to-point;
  the producer knows the consumer; usually one-to-one; still logically coupled (e.g. Order →
  Payment).
- **Event-driven = how the system behaves (the architecture)** — the producer knows nothing
  about consumers; one-to-many; focuses on business flow.
- Messaging can exist without event-driven; **event-driven requires messaging.**

### 12.5 Key resilience patterns for messaging (include all)
- **Idempotency (safe retries)** — the most important. With at-least-once delivery the same
  message may arrive twice; processing must be safe to repeat. **Typical pattern — processed
  message table:**
  ```
  processed_messages(event_id PK/UNIQUE, processed_at, consumer_name)
  // consumer logic:
  receive event
  if event_id already exists -> skip
  else: do business work; insert processed record; commit (same transaction)
  ```
  Also expose **idempotency keys** on write APIs (e.g. payments/order-creation):
  `Idempotency-Key` header → store result keyed by it → safe client retries.
- **Retry with backoff** — handle transient failures (exponential backoff + jitter; cap
  attempts). **Retry reads freely; retry writes only when idempotent.**
- **Dead Letter Queue (DLQ)** — route permanently failing messages aside for inspection instead
  of infinite retry.
- **Eventual consistency** — the system converges over time; accept that cross-service state is
  not instantly consistent.
- **No global/distributed ACID transactions** across services — you cannot auto-rollback across
  service boundaries. Use the **SAGA pattern**: a sequence of local transactions with
  compensating actions on failure.
- **Outbox pattern (reliable messaging)** — problem: DB commit succeeds but the broker publish
  fails. Solution: in the *same* transaction, save business data **and** an `outbox_events` row;
  a background worker publishes events and marks them published. Avoids losing business events.

### 12.6 Implementation shape (any broker/language)
```
// contract: immutable event carrying a traceId for observability
record OrderCreatedEvent(eventId, orderId, userEmail, amount, traceId)

// producer
producer.publish("order-created", new OrderCreatedEvent(...))

// consumer (async: no HTTP, no controller, no request filter)
onMessage("order-created"): {
  context.set("traceId", event.traceId)   // MUST manually restore trace context
  try { doWork(event) } finally { context.clear() }
}
```
What the framework gives you automatically: broker connection, consumption, deserialization,
threading. What **you** must handle: trace propagation, business logic, error handling,
idempotency.

---

## 13. Resilience patterns (transient-fault handling)

Transient faults occur in any network/service communication — you need a recovery strategy.

- **Retries** — with exponential backoff + jitter; bounded attempts; only safe for idempotent
  operations.
- **Circuit breaker** — when a downstream service keeps failing, "open" the circuit and fail
  fast (with a fallback) instead of piling up calls; periodically half-open to test recovery.
  Prevents one failing service from crashing the whole system. Pair with a **fallback method**
  returning a safe default.
- **Timeouts everywhere** — a slow dependency must not consume all server threads; configure
  timeouts on every outbound HTTP/DB/broker call. *An HTTP client is how your service talks to
  others — configure it or it will break your system.*
- **Bulkheads & rate limiting** — isolate resource pools; cap inbound load.
- **Telemetry + alerts** — custom metrics to watch component health; raise alerts when a metric
  crosses a threshold or a custom event occurs (§14).

These map to libraries in every stack (Resilience4j/Polly/opossum/tenacity/`sony/gobreaker`),
but the **patterns** are what matter.

---

## 14. Observability: metrics, logs, traces

> Without observability you are blind and debugging is guessing. With it you can **measure,
> detect, explain, and fix**. Make every production service self-observable from day one.

### 14.1 The three pillars
- **Metrics** (numbers over time) — request count, latency, error rate, CPU/memory, **custom
  business metrics**. Used for dashboards and alerting.
- **Logs** (events) — structured records of what happened. Used for debugging.
- **Traces** (request journeys) — follow one request across services/operations. Used for
  distributed systems.

A health/metrics endpoint gives the **data**; collection/visualization tools give the
**insight**.

### 14.2 Metrics pipeline
A metrics facade/abstraction (Micrometer, `System.Diagnostics.Metrics`, prom-client,
prometheus_client) exposes metrics in a standard format; a **collector** (Prometheus, pull-based,
scrapes a `/metrics`-style endpoint periodically) stores them over time; a **visualizer**
(Grafana) builds dashboards. Standard flow: `app + metrics lib → expose endpoint → Prometheus
scrapes → Grafana visualizes`.

- **Metric model**: `metric_name{labels} value`. Labels are dimensions for filtering/aggregation
  (`method`, `status`, `uri`, `outcome`).
- **Counters** (monotonic totals, e.g. requests handled) and **timers/histograms** (give
  count + sum + distribution buckets for latency percentiles).
- **Custom business metrics** are the most valuable from a product view (orders created by type,
  failed orders, lookup duration). Inject the meter registry and create counters/timers.
- **Common queries (PromQL-style):** requests/sec = `rate(http_requests_total[1m])`;
  error rate = `rate(http_requests_total{status="500"}[1m])`; per-endpoint rate with a `uri`
  label; 95th-percentile latency =
  `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[1m]))`.

With observability you can answer: "orders dropped 40% in the last hour", "express orders spike
at 6 PM", "95th-percentile latency is 800ms — problem?", "failures increased right after the
deploy".

### 14.3 Logging
- **Log levels:** DEBUG (developer detail) · INFO (normal operations) · WARN (unexpected but
  handled) · ERROR (failure). Use parameterized messages, not string concatenation.
- **Profile-aware config**: console logging in dev/test; rolling file (or shipped) logging in
  prod with retention. Keep DEBUG **out** of production (cost + performance + data risk).
- **Structured logging** (JSON with `timestamp`, `level`, `traceId`, business ids, `message`) so
  logs are searchable in ELK/Loki/Splunk/cloud logging.

### 14.4 Correlation IDs / traceId & MDC-style context
- A **traceId** is a unique id for one business request flow across multiple services; all
  related log lines and downstream calls share it so you can correlate everything.
- Generate it at the **first entry point** — API gateway if present, otherwise a request
  filter/interceptor in the first service (a "once-per-request" filter is cleaner than doing it
  in the controller). Read an inbound `X-Trace-Id`/`X-Correlation-Id` if present, else generate
  a UUID.
- Store it in a per-thread/async logging context (**MDC** = Mapped Diagnostic Context in
  SLF4J; equivalents elsewhere) so **every** log line auto-includes it, then **clear it** at the
  end of the request to avoid leakage.
- **Propagate** it: into outbound HTTP requests (as a header), into messages/events (as a
  payload field or header), and restore it in async consumers. Add it to the logging pattern so
  lines look like `... traceId=9f3a2c7b OrderService - Saving order`.

### 14.5 Distributed tracing (traces & spans)
- **Trace** = the whole journey of one request across the system; **Span** = one operation inside
  it (controller handling, payment call, inventory call, DB save).
- **Level 1 (lightweight)**: correlation IDs in structured logs.
- **Level 2 (real tracing)**: a tracing library (Micrometer Tracing, OpenTelemetry) + a backend
  (OTLP/Jaeger, Zipkin/Brave, Tempo). Wrap important operations in spans (external calls — DB,
  API, broker; key business steps; potentially slow operations) so you can see *inside* a request,
  not just total time. Control sampling probability (1.0 traces everything; lower in high-volume
  prod).

---

## 15. Caching & performance

- **Declarative caching** — cache expensive reads with a cache abstraction (Spring Cache,
  `IMemoryCache`/`IDistributedCache`, Nest CacheModule, Django/Flask caching) backed by
  in-memory / Redis / Caffeine. Keyed by inputs; replaceable backend. Reduces DB/external load.
- **Pagination by default** — never return unbounded result sets; accept page/size (or
  cursor) parameters.
- **Avoid N+1 queries** — fetching a list then lazily loading each child runs 1 + N queries.
  Fix with fetch-joins / eager loading on demand / batch loading. Understand **lazy loading**:
  related data isn't loaded until accessed; risks are `LazyInitializationException`-style errors
  when the session is closed, and the N+1 performance disaster.
- **Projections / read models** — fetch only needed columns for read-heavy APIs instead of full
  entities; consider **CQRS** (separate read/write models or even databases) for heavy read/write
  asymmetry.
- **Connection pooling** — size the pool correctly (e.g. HikariCP max-pool-size, min-idle,
  connection-timeout) to prevent uncontrolled DB connections and improve throughput.
- **HTTP response compression** (gzip) for large JSON; **stream** large responses (CSV/Excel/
  reports/file downloads) instead of loading them fully into memory.
- **Virtual threads / async I/O** — for blocking I/O-heavy workloads (many concurrent DB/API/file
  calls), virtual threads (or the stack's async model) improve scalability; not a fix for
  CPU-bound work.

---

## 16. Asynchronous & scheduled work (in-process)

- **Async background execution** (`@Async`, `Task.Run`/hosted services, worker queues, asyncio
  tasks, goroutines) — run non-critical work off the request thread (send email, external
  logging, generate report) so the response returns quickly. **Always configure your own thread
  pool explicitly** (core size, max size, queue capacity, name prefix); the default executor can
  overload the app. **Limitations:** in-process async is **not durable, not distributed, lost on
  crash** — use it only for local, non-critical background tasks. For durable distributed work use
  messaging (§12).
- **Scheduled jobs** (`@Scheduled`, hosted timers, cron libraries) — periodic/at-fixed-time tasks
  (cleanup, sync, reports, retrying failed events). Use fixed-rate/fixed-delay or cron
  expressions (`second minute hour day-of-month month day-of-week`). For multi-instance
  deployments, guard scheduled jobs with leader election / a distributed lock so they don't run
  on every instance.
- **Decision rule:** Messaging → durable, distributed service communication. Async → local,
  non-durable background task. Scheduled → time-based local jobs.
- **Domain events (in-process)** — decouple a business action from its side effects by publishing
  an in-app event that listeners handle. Default in-process events are synchronous; prefer async
  handling for slow side effects. **Transactional events** — run side effects only *after commit*
  (an "after-commit" phase) so you don't send an email/message when the transaction rolls back.

---

## 17. Testing strategy — the enterprise pyramid

> **Why test:** enterprise systems must guarantee security, tenant isolation, data integrity and
> reliability. Untested security → data breaches; ignored tenant isolation → cross-tenant leaks;
> untested transactions → corrupted data; ignored concurrency → race conditions/duplicates; no
> CI/CD testing → production outages. Testing is part of CI/CD, **not optional**.

### 17.1 The pyramid & the target ratio
```
        /\        E2E  (few, slow, expensive)        ~10%
       /  \       API / Contract tests
      /----\      Integration tests                  ~20%
     /------\     Unit tests (many, fast, isolated)  ~70%
```
**Recommended strategy: 70% unit / 20% integration / 10% E2E.** Catch most bugs at the unit
level; the higher the test, the more expensive — write fewer of them. Optimize for **speed +
confidence**.

### 17.2 Layer by layer
- **Unit tests** — single class/function; **no framework context, no DB, no network**; mock all
  dependencies; deterministic & fast. For each important method test: **happy path,
  exception/failure, invalid input, edge case.** Verify *both* result correctness (assert the
  value) *and* collaboration correctness (verify the right dependency calls happened). Tools:
  a runner (JUnit / xUnit / Jest / pytest / `go test`) + a mocking library (Mockito / Moq /
  jest mocks / unittest.mock / gomock).
- **Integration tests** — multiple components together (service + repository + DB, ORM +
  transactions); real config + DB; moderate count, realistic. Use **test slices** for partial
  context (web-layer-only, persistence-layer-only) to stay fast, and a **full-context** option
  for true integration. Prefer **real databases in containers (Testcontainers)** over in-memory
  fakes — in-memory engines (H2) can hide real bugs; containers run the production DB engine and
  expose them.
- **API / contract tests** — the HTTP layer: controller + validation + serialization,
  request/response contracts, status codes, JSON structure. Black-box, validate the **external
  contract** clients see. Tools: in-memory HTTP test clients (MockMvc) / fluent HTTP testers
  (RestAssured) / supertest / `httpx` / `httptest`.
- **E2E / smoke tests** — full system, real HTTP + real DB + real services, user-perspective
  flows (e.g. login → get token → call secured endpoint). Very slow; keep few. Start the whole
  app on a random port.

### 17.3 What MUST be tested in enterprise systems
| Concern | Why |
|---|---|
| Authentication | identity correctness (e.g. no token → `401`) |
| Authorization (RBAC) | access control (wrong role → `403`) |
| Tenant isolation | data security (tenant A → tenant B's record → `403`/`404`) |
| Transactions | data consistency (exception mid-transaction → no partial writes) |
| Concurrency | correctness under load (parallel updates / duplicate creation / optimistic-lock conflict) |
| Observability | system visibility (health/metrics endpoints return `200`) |

Use security-test helpers (mock authenticated users with roles) for RBAC tests, multi-thread
simulations for concurrency tests, and assertions on rollback/no-partial-write for transaction
tests.

### 17.4 A minimal enterprise coverage baseline for a feature
~2–3 unit tests · 1 integration · 2 API · 2 security · 1 E2E. Add **performance testing**
(simulate concurrent users, measure latency/throughput with Locust/k6/Gatling/JMeter) for
critical paths.

### 17.5 Common testing mistakes
Testing only happy paths · ignoring security tests · not testing tenant isolation · missing
transaction-rollback & concurrency tests · too many E2E tests (slow pipelines) · testing the
wrong layer · poor isolation · using full-app context for unit logic · hitting a real DB in unit
tests.

**Layer → what you protect:** Unit = logic correctness · Integration = system wiring · API =
contract stability · E2E = user experience · CI/CD = deployment safety.

---

## 18. CI/CD

Automate build, test and deploy: `Code → Build → Test → Deploy`. Enforce **quality gates**;
**fail fast**; **stage tests by cost**; generate coverage reports. Reduces human error.

**A layered pipeline (mirror this in GitHub Actions / GitLab CI / Jenkins):**
1. **CI (on push):** build + compile → lint/static analysis → **unit tests** → web-layer slices
   (fast, seconds).
2. **Quality gate (on PR):** integration tests → API tests → security scans → coverage check.
3. **On merge to main / full validation:** E2E tests → build container image → push to registry.
4. **Deploy to staging → smoke tests** (very important: app starts? DB reachable? `/health`
   200? core endpoint works?) → **pass = continue, fail = rollback** → deploy to production.

Stage by cost so feedback is fast where it is cheapest. Run security tests and tenant-isolation
tests in the gate, not just locally.

---

## 19. Containerization, orchestration & production readiness

### 19.1 Containers & Compose
Package the app as a self-contained image (embedded server, no external app server needed) —
simplifies CI/CD, ideal for containers/orchestration, enables microservices. **Docker Compose**
defines a multi-container system (services, ports, internal networking by service name, env
injection, volumes, one-command startup) — great for dev. **Compose limitations** (why it's not
production orchestration): no real load balancing, no self-healing, single machine, weak secrets,
limited traffic routing, downtime on updates.

### 19.2 Kubernetes (K8s) core concepts
K8s is a container-orchestration platform — an "operating system for distributed apps". You
**declare desired state**; a **reconciliation/control loop** continuously makes reality match
(restart crashed containers, replace pods, reschedule on healthy nodes, scale, discover services,
roll updates). Result: self-healing, scalable, production-ready systems.

- **Control plane:** API Server (entry for all requests), Scheduler (assigns pods to nodes),
  Controller Manager (background loops maintaining desired state), **etcd** (key-value store of
  cluster state).
- **Worker nodes:** Pods (smallest deployable unit; one+ containers sharing network/storage),
  the container runtime, **Kubelet** (node agent), **Kube-proxy** (network rules + load
  balancing).
- **Pod** = a running instance of your app. **Deployment** = declares replica count and keeps the
  desired number running (`replicas: 3`). **Service** = stable IP/DNS endpoint in front of pods
  (pods change IPs; a Service gives stable access + load balancing). **ConfigMap** = non-sensitive
  config; **Secret** = sensitive data (base64-encoded, **not encrypted** by default → use
  encryption at rest + a secret manager like Vault / AWS Secrets Manager / Azure Key Vault).
- **Service discovery via DNS (CoreDNS):** a Service named `backend` is reachable as
  `http://backend` inside the cluster. Flow: `App → CoreDNS → Service IP → kube-proxy → Pod`.
  K8s replaces Eureka/Consul (discovery) and Nginx/HAProxy (LB) with CoreDNS + Service +
  kube-proxy, configured declaratively.
- **Service types:** ClusterIP (internal only) · NodePort (expose on a node port) · LoadBalancer
  (cloud LB). Define a **deployment + service** per microservice (and for stateful deps like DB).
- **`kubectl`:** `apply -f` (declarative update; cluster stores desired state in etcd, controllers
  enforce), `get pods/deployments`, `describe pod`, `logs`, `scale`, `delete -f`,
  `rollout restart`, `rollout undo`. When reading any YAML, identify: `kind` (what resource),
  `spec` (desired state), `selector`/`labels` (routing), `containers` (what runs).

### 19.3 Production-critical K8s features (non-negotiable)
- **Health probes** — **liveness** (is the app stuck → restart it), **readiness** (can it receive
  traffic now → else stop routing), and **startup** (is it initialized) probes, pointing at a
  health endpoint with correct `initialDelaySeconds`/`periodSeconds`. Probes **must match real
  startup time** or you get CrashLoops.
- **Resource requests & limits** — CPU/memory `requests` and `limits` per container; without them
  you get OOMKills and noisy-neighbor problems. CPU-based autoscaling **requires** CPU requests.
- **Ingress (production routing)** instead of NodePort: NodePort exposes non-standard high ports
  with no host/path routing and no TLS. **Ingress** = Layer-7 HTTP(S) routing (host-based,
  path-based, TLS termination) and **needs an Ingress controller** (e.g. NGINX). Talk to a
  Service in dev, Ingress in prod; never talk to pods directly. (Service = L4/TCP; Ingress =
  L7/HTTP.)

### 19.4 Scaling & zero-downtime deploys
- **Manual scaling:** `kubectl scale deployment app --replicas=5`.
- **Rolling updates** (zero downtime): change the image; the Deployment controller starts a new
  pod, waits until healthy, then stops an old one, repeating; the Service keeps routing because
  old and new pods share the same label. Roll back with `rollout undo`.
- **HPA (Horizontal Pod Autoscaler):** scales replicas on CPU/metric utilization
  (`minReplicas`/`maxReplicas`, `averageUtilization`); requires CPU requests and a **metrics
  server**.
- **Blue/green & canary** deployments for risky releases: keep two deployments and switch the
  Service selector (blue↔green), or shift a fraction of traffic (canary) before full rollout.
- **Graceful shutdown:** enable graceful shutdown with a shutdown timeout so in-flight requests
  finish before the pod stops — essential for rolling updates.

### 19.5 Common K8s failure scenarios & fixes
CrashLoop → bad probe timing → increase `initialDelaySeconds` to match startup · networking →
wrong port mapping → align `containerPort`/`targetPort`/`port` (`Client → Service(port) →
Pod(targetPort) → Container(containerPort)`) · missing secret → app crashes → reference via
`secretKeyRef` · OOM → no memory limit → set requests/limits (diagnose with `describe pod`
[OOMKilled], `top pod`, `top node`) · bad deploy → no rollout strategy → canary/blue-green ·
can't debug → no logs/metrics → add observability (§14).

### 19.6 Startup optimization (cloud/serverless)
Heavy runtimes (e.g. JVM) have slow startup and large memory footprints → autoscaling delays,
serverless cold starts, high infra cost, poor pod density. Mitigations: **Ahead-Of-Time (AOT)
compilation** (move classpath scanning / DI wiring / proxy generation from runtime to build
time) and **native images** (e.g. GraalVM → standalone binary, very fast startup, low memory).
Use for microservices, K8s autoscaling, serverless, edge; avoid when you need heavy dynamic
reflection, fast dev iteration, easy debugging, or use libraries that aren't native-compatible.
Other stacks have analogous trade-offs (Node bundling, Python startup cost, Go's already-fast
native binaries).

---

## 20. Infrastructure as Code (IaC)

An enterprise system is more than your app and K8s: cloud provider, networking (VPC, subnets,
firewalls), databases, load balancers, the K8s cluster itself, storage, IAM roles. Creating these
by hand causes environment drift (dev ≠ staging ≠ prod), no reproducibility, hard auditing, setup
errors, and "works on staging, fails in production". **IaC** defines infrastructure as
versioned code and a tool provisions it automatically.

- **Kubernetes is not enough** — K8s manages what runs *inside* a cluster; it does **not** create
  the VPC/network, cloud databases, IAM roles, cloud load balancers, or the cluster itself. Layer:
  **IaC (Terraform/Pulumi) → infrastructure → Kubernetes → application.**
- **Tool types:** **declarative/state-based** (Terraform, CloudFormation — you declare the
  desired state, the tool computes how to reach it) vs **imperative/programmatic** (Pulumi — real
  code with loops/conditions in Python/TS/Go).
- **Terraform core concepts:** `terraform{}` (engine constraints, providers, remote **state**
  backend + locking), `provider{}` (API binding/driver), `variable{}` (inputs → reuse + env
  separation → "build once, deploy everywhere"), `resource{}` (desired state — the core; Terraform
  builds a dependency graph and computes create/update/destroy), `data{}` (read existing infra),
  `locals{}` (computed values), `module{}` (composition/reuse), `output{}` (exposed results for
  CI/CD chaining). State file tracks what exists/changed. Flow: `init → plan (diff) → apply`.
- **Terraform vs Kubernetes:** Terraform is a desired-state *infrastructure planner* ("what infra
  should exist?"); K8s is a runtime *orchestration controller* ("how do I keep apps healthy
  now?"). They complement, not replace, each other.
- **Local clusters for dev/CI:** Minikube (single-node local cluster) and Kind (Kubernetes-in-
  Docker; each node is a Docker container; fast, lightweight, real K8s — not a simulation).
- **IaC value:** consistency, reproducibility, automation, auditability, version control —
  identical environments from the same code.

---

## 21. Optional AI augmentation (only when it fits)

AI augments the backend; it does **not** replace it. Backend logic remains the source of truth
for correctness, validation and transactions.

- **Decision rule:** use AI when the feature needs **language + ambiguity + interpretation**
  (knowledge Q&A over policies, document summarization, semantic search, support assistants,
  ticket classification, recommendations, explanation, drafting, multi-step reasoning). Use
  **normal deterministic backend** when the feature needs **correctness + determinism +
  transactions** (GPA/financial calculation, payment execution, auth decisions, inventory
  deduction, real-time/hard-constraint rules).
- **Standard pattern:** `Client → Controller → Service → AI client → RAG + memory + tools → LLM`.
  **RAG** (Retrieval-Augmented Generation): user question → embed → vector search → retrieve
  relevant chunks → inject into prompt → grounded answer (don't answer from raw model knowledge).
  **Tool calling** lets the model invoke whitelisted backend methods; **memory** scopes
  conversation per session.
- **Enterprise safety controls (mandatory):** never trust AI output directly — AI suggests,
  **backend validates, then executes**; always ground answers via RAG; **whitelist** callable
  tools; validate inputs; constrain outputs (structured JSON); **human-in-the-loop** for
  sensitive actions; log/audit (prompt, response, tool used, user id); control cost (token
  limits, caching, smaller models). Risks to manage: hallucination, cost, latency, data leakage,
  non-determinism, debugging difficulty.

---

## 22. Checklists — Definition of Done

### 22.1 New service / endpoint
- [ ] Layered: thin controller → service (business + tx boundary) → repository.
- [ ] Constructor injection; no field injection; no stateful singletons.
- [ ] Request DTO + response DTO; entities never exposed.
- [ ] Validation in all three layers (syntactic/semantic/cross-field).
- [ ] Stable, machine-readable error model via a global handler; `traceId` included.
- [ ] Versioned base path (`/api/v1/...`); evolution plan for breaking changes.
- [ ] AuthN + AuthZ (request-level **and** method-level RBAC where relevant).
- [ ] Tenant isolation enforced from the **token**, never client input (if SaaS/multi-tenant).
- [ ] Transaction boundary correct; rollback on failure; right isolation level; locking where
      needed (optimistic by default, pessimistic for hot rows).
- [ ] Idempotency for writes that can be retried (idempotency key and/or processed-message
      table); timeouts on all outbound calls.
- [ ] Observability: structured logs + correlation ID, key metrics, spans on external/slow steps,
      health endpoint.
- [ ] Caching/pagination/projections where reads are heavy; no N+1.
- [ ] Tests at 70/20/10 covering happy/failure/invalid/edge, plus security, tenant isolation,
      transactions, concurrency, observability.
- [ ] Config externalized & typed & validated at startup; secrets from env/secret manager;
      same artifact across environments.

### 22.2 Production readiness
- [ ] Containerized; immutable artifact built once, deployed many times.
- [ ] Liveness + readiness (+ startup) probes; resource requests & limits set.
- [ ] Graceful shutdown enabled.
- [ ] Rolling update (or blue/green / canary) strategy; rollback path tested.
- [ ] HPA configured (with CPU requests + metrics server) if traffic-driven scaling is needed.
- [ ] Ingress + TLS in production (not NodePort); service discovery via DNS.
- [ ] CI/CD with staged tests, quality gates, smoke tests after deploy, auto-rollback on failure.
- [ ] IaC for all infrastructure; state managed remotely with locking.
- [ ] Secrets encrypted at rest; least-privilege IAM.
- [ ] Dashboards + alerts on golden signals (latency, traffic, errors, saturation).

---

## Appendix A — Enterprise anti-patterns to refuse

- Hard-coded environment values or secrets in code/repo.
- Business logic or repository calls inside controllers.
- Exposing ORM entities directly across the API.
- Field injection / `new`-ing dependencies / stateful singleton services.
- Storing request/tenant-specific data in singleton scope.
- Self-invocation that silently bypasses transaction/security/audit proxies.
- Trusting client-supplied tenant id instead of the token claim.
- Retrying non-idempotent writes without an idempotency key.
- In-memory async for work that must be durable (use messaging).
- Inconsistent ad-hoc error JSON; leaking stack traces/DB structure.
- Over-engineering / pattern misuse where the problem doesn't exist.
- Skipping security, tenant-isolation, transaction and concurrency tests.
- Too many E2E tests instead of the 70/20/10 pyramid.
- NodePort + no TLS in production; missing probes / resource limits; no graceful shutdown.
- Manual ("click-ops") infrastructure causing environment drift.
- Trusting AI output without backend validation; un-grounded (no-RAG) answers; un-whitelisted
  tool calls.

## Appendix B — Trade-off awareness (always reason under the hood)

Frameworks make things easy but **abstraction hides complexity** and **annotations hide
execution flow**; misconfiguration causes production issues. Good engineers understand what
happens beneath the abstraction: how DI wiring, proxies, transactions, isolation, the security
filter chain, message delivery, the K8s control loop and Terraform state actually behave. Choose
isolation/consistency/availability trade-offs deliberately (stronger isolation ⇒ less
concurrency; eventual consistency ⇒ more availability; more E2E tests ⇒ slower pipelines). Match
the pattern to the real NFRs of the project, in whatever language it is written.
