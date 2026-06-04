<!-- GSD:project-start source:PROJECT.md -->
## Project

**skyproject — Android Projector Beta**

skyproject projects the aircraft passing overhead — plus the real sky (sun, moon, bright
stars + constellations, satellites/ISS) — onto a ceiling in real time, an "X-ray through
the roof." This milestone adapts the existing Raspberry-Pi + RTL-SDR appliance to run with
**no radio and no Pi**: the Node server runs on the user's **Mac**, and an **Android
projector's built-in browser** renders the full-screen display over the local Wi-Fi
network. Centered on **London** for the beta.

**Core Value:** A live, hardware-free "X-ray through the roof" in London — the planes actually overhead,
plus the true sky, drawn on the ceiling from the projector's own browser, with nothing
running but the existing server on a Mac.

### Constraints

- **Tech stack**: Keep the existing TS / React / Express / `ws` / Vite stack — "without much changes" is an explicit goal.
- **Network**: Mac and projector must share the same Wi-Fi; the Mac must be running and awake while in use.
- **Platform**: Android projector browser (Chrome/WebView) — must handle fullscreen, screensaver/keep-awake, and possibly an older WebView. Canvas 2D + `requestAnimationFrame` + WebSocket are all well-supported; `maxFps` helps weaker GPUs.
- **Data**: public airplanes.live API — stay polite to rate limits (`API_POLL_MS` default 4000 ms).
- **Hardware**: No Raspberry Pi, no RTL-SDR.
- **Location precision**: "London" must be set to the user's actual neighborhood/coordinates so planes are genuinely *overhead* within `radiusMiles` (exact point TBD at config time).
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- TypeScript 5.7.x - All source code across server, web, and shared packages
- Bash - Deployment and setup scripts (`pi-setup/`, `scripts/`)
## Runtime
- Node.js >=20 (enforced via `engines.node` in `package.json`)
- pnpm 10.28.2 (pinned via `packageManager` field)
- Lockfile: `pnpm-lock.yaml` — present and committed
## Frameworks
- React 18.3.x - UI components for display (`web/src/display/`) and control (`web/src/control/`) pages
- Express 4.21.x - HTTP server, REST API, static file serving (`server/src/index.ts`)
- ws 8.18.x - WebSocket server (`server/src/hub.ts`)
- Vite 6.0.x - Frontend bundler and dev server (`web/vite.config.ts`)
- @vitejs/plugin-react 4.3.x - React Fast Refresh and JSX transform for Vite
- tsx 4.19.x - TypeScript execution for Node.js (used in `server/` dev and prod)
- concurrently 9.1.x - Runs server and web dev processes in parallel (root `package.json`)
- Playwright 1.60.x - Installed at root but no test files detected; likely used for screenshot tooling (`scripts/screenshot.mjs`)
## Key Dependencies
- `astronomy-engine` 2.1.x (`web/`) - Computes sun, moon, and star horizontal coordinates for the sky layer (`web/src/display/celestial.ts`)
- `satellite.js` 5.0.x (`web/`) - SGP4/SDP4 orbital propagation; computes satellite positions from TLEs (`web/src/display/celestial.ts`)
- `ws` 8.18.x - Low-level WebSocket server that broadcasts aircraft/config/status to all connected clients (`server/src/hub.ts`)
- `express` 4.21.x - HTTP layer serving REST API and production static build (`server/src/index.ts`)
## Configuration
- `PORT` - HTTP/WS server port (default `3000`)
- `HOST` - Bind address (default `0.0.0.0`)
- `DATA_SOURCE` - `radio` or `api` (default `radio`)
- `AIRCRAFT_JSON_URL` - dump1090 aircraft.json endpoint (default `http://localhost:8080/data/aircraft.json`)
- `API_URL` - airplanes.live point URL template (default `https://api.airplanes.live/v2/point/{lat}/{lon}/{r}`)
- `POLL_MS` - Primary poll interval ms (default `1000`)
- `SUPPLEMENT_API` - `0` to disable API supplement when in radio mode (default `1`)
- `API_POLL_MS` - API supplement poll interval ms (default `4000`)
- `ROUTE_CACHE_HOURS` - adsbdb route cache TTL (default `12`)
- `TLE_URL` - Override Celestrak TLE URL (default `https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle`)
- `tsconfig.base.json` - Shared TypeScript config (ES2022, strict, `@shared/*` path alias)
- `server/tsconfig.json` - Server-specific config (NodeNext module resolution)
- `web/tsconfig.json` - Web-specific config (Bundler module resolution)
- `web/vite.config.ts` - Multi-page build (index.html + control.html), `@shared` alias, dev proxy to server
- `server/data/config.json` - User-adjusted Config object, written by `ConfigStore`
- `server/data/route-cache.json` - adsbdb route/aircraft enrichment cache
- `server/data/tle-cache.json` - Celestrak TLE cache
## Platform Requirements
- Node.js >=20, pnpm 10.x
- Optional: RTL-SDR dongle + dump1090-fa for live radio source
- `scripts/run-dump1090-local.sh` for local radio simulation on Fedora
- `scripts/install-rtlsdr-fedora.sh` for RTL-SDR drivers on Fedora
- Raspberry Pi (target deployment platform), kiosk-mode Chromium for the display
- systemd service via `pi-setup/skyproject-server.service` (`pi-setup/install-on-pi.sh`)
- Projector connected to Pi HDMI for ceiling display
- `scripts/deploy-to-pi.sh` for rsync-based deployment
## Monorepo Structure
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- `kebab-case.ts` for server modules: `config-store.ts`, `datasource.ts`
- `camelCase.ts` for pure utility/data files: `aircraftGlyph.ts`, `celestial.ts`, `useStream.ts`
- `PascalCase.tsx` for React components: `Display.tsx`, `Control.tsx`, `components.tsx`
- `kebab-case.ts` preferred in `server/` and `shared/`; camelCase used in `web/src/display/`
- PascalCase: `ConfigStore`, `RouteEnricher`, `Poller`, `Hub`, `TleStore`, `Connection`, `Renderer`
- PascalCase for both: `Aircraft`, `Config`, `PollerOptions`, `HubDeps`, `StreamState`, `GlyphKind`
- Use `interface` for object shapes (including exported domain models); use `type` for union strings and discriminated unions
- Union string types: `type Theme = "ambient" | "telemetry" | "focus"` (`shared/src/config.ts`)
- Discriminated union message types: `type ServerMessage = { type: "config" } | ...` (`shared/src/messages.ts`)
- camelCase for module-level functions: `normalize`, `mergeSources`, `fetchJson`, `lookupType`, `llToMeters`, `deadReckon`
- camelCase for class methods, prefixed `private` keyword (no underscore prefix): `onConnect`, `scheduleSave`, `buildApiUrl`
- camelCase for locals and instance fields: `configRef`, `connRef`, `ttlMs`, `inflight`
- `SCREAMING_SNAKE_CASE` for module-level constants: `NM_PER_MILE`, `RENDER_DELAY_MS`, `EMERGENCY_SQUAWKS`, `DEFAULT_CONFIG`, `ALT_STOPS`
- Environment variable reads at server startup use `SCREAMING_SNAKE_CASE`: `PORT`, `HOST`, `SOURCE`, `POLL_MS`
- PascalCase named exports: `Section`, `Row`, `Toggle`, `Slider`, `Segmented`, `ColorRow`
- Props typed inline with destructured parameter signatures, not separate prop interfaces
## Code Style
- No Prettier or ESLint config files found — formatting is enforced by TypeScript strict mode and code review
- 2-space indentation throughout
- Double quotes for strings (consistent across all files)
- Trailing commas in multi-line objects/arrays/parameters
- Strict mode enabled globally via `tsconfig.base.json`: `strict`, `noUnusedLocals`, `noUnusedParameters`, `noFallthroughCasesInSwitch`, `noImplicitOverride`
- `verbatimModuleSyntax: true` — forces `import type` for type-only imports everywhere
- `isolatedModules: true` — no ambient type merging
## Import Organization
- `@shared/*` resolves to `shared/src/*` — configured in `tsconfig.base.json`, `web/tsconfig.json`, and `web/vite.config.ts`
- All relative imports must include `.js` extension (required by ESM with `"moduleResolution": "Bundler"`): `"./config-store.js"`, `"../lib/useStream.js"`
- JSON imports use import assertions: `import airlines from "./airlines.json" with { type: "json" }`
- Always use `import type` when importing only type symbols: `import type { Aircraft, Config } from "@shared/index.js"`
- Mixed value+type imports split inline: `import { DEFAULT_CONFIG, mergeConfig, type Config } from "@shared/index.js"`
## Error Handling
## Logging
- Server logs are prefixed with a bracketed module tag: `[server]`, `[tle]`, `[config]`
- Log only on startup, status changes, and errors — never in per-frame or per-poll hot paths
- Client-side code has no console logging (intentional — avoids noise in browser devtools)
## Comments
- Module-level file headers: one-line or short paragraph explaining what the module does and any important design decisions
- Non-obvious algorithms get inline explanation: interpolation delay rationale (`renderer.ts:1–12`), sticky enrichment logic (`datasource.ts:239`), route plausibility algorithm (`renderer.ts:1018–1061`)
- JSDoc `/** */` used for exported functions with non-obvious parameters or return semantics: `mergeConfig`, `deadReckon`, `lookupAirline`, `mergeSources`, `enrichSync`
- Short inline `// comments` for logical sections within methods: `// Prime the new client`, `// REST API`, `// static web (production build)`
- Applied selectively to public API functions in `shared/` and exported class methods
- Parameter descriptions in JSDoc where units matter (e.g., degrees, feet, ms)
## Function Design
- Options objects (`interface PollerOptions`, `interface SkyOpts`) for constructors/functions with many parameters
- Constructor dependency injection: `constructor(private o: PollerOptions)` and `constructor(server: Server, private deps: HubDeps)`
- Callbacks passed as interface fields rather than standalone function arguments
- `null` (not `undefined`) to indicate "intentionally absent" scalar results: `altBaro: number | null`, `fetchList` returning `null`
- `undefined` for optional fields on interfaces that were never set
- `Promise<void>` for async side-effect methods; `Promise<T>` when a value is returned
## Module Design
- Named exports throughout — no default exports anywhere
- `shared/src/index.ts` is a pure re-export barrel: `export * from "./config.js"` etc.
- Server and web modules export only what callers need; implementation interfaces (e.g., `RawAircraft`, `StickyEnrichment`, `CacheFile`) are kept unexported
- Only `shared/src/index.ts` acts as a barrel; server and web packages import directly from specific files
- The `@shared` alias always resolves through `shared/src/index.ts`
## Class Design
- Use numeric separators for large millisecond/time constants: `3600_000`, `600_000`, `15_000`
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## System Overview
```text
```
## Component Responsibilities
| Component | Responsibility | File |
|-----------|----------------|------|
| `Poller` | Poll ADS-B sources, normalize, merge, enrich, emit snapshots | `server/src/datasource.ts` |
| `Hub` | Manage WebSocket clients, broadcast messages, apply inbound config commands | `server/src/hub.ts` |
| `ConfigStore` | Persist and broadcast Config; merge patches; notify subscribers | `server/src/config-store.ts` |
| `TleStore` | Fetch, cache, and serve satellite TLEs from Celestrak | `server/src/tle.ts` |
| `RouteEnricher` | Look up flight routes and aircraft detail from adsbdb.com, disk-cached | `server/src/enrich/routes.ts` |
| `lookupType` / `lookupAirline` | Instant static lookups from bundled JSON tables | `server/src/enrich/tables.ts` |
| `Renderer` | Canvas 2D render loop: interpolated aircraft, trails, sky, overlays | `web/src/display/renderer.ts` |
| `Display` | React shell for the projector page; bridges WS stream to Renderer | `web/src/display/Display.tsx` |
| `Control` | React UI for phone-based live config editing | `web/src/control/Control.tsx` |
| `Connection` | Auto-reconnecting WebSocket client; shared state bus for a page | `web/src/lib/connection.ts` |
| `useStream` | React hook wrapping `Connection` for a page's lifetime | `web/src/lib/useStream.ts` |
| Shared types & math | `Config`, `Aircraft`, `ServerMessage`/`ClientMessage`, geo math | `shared/src/` |
## Pattern Overview
- Server is the single source of truth: all config changes flow through `ConfigStore` and are broadcast to all connected clients simultaneously.
- Data acquisition is fully decoupled from presentation: `Poller` calls `onSnapshot` callback; `Hub` distributes; renderer consumes.
- Both web pages (display + control) are structurally identical React SPA shells that each open one WebSocket to `/ws` and declare their role via a `hello` message.
- Shared package (`shared/`) holds all types and pure math referenced by both server and web without runtime coupling.
- The renderer runs a `requestAnimationFrame` loop independently of the server poll cadence; interpolation bridges the gap.
## Layers
- Purpose: Poll external ADS-B sources, normalize raw records into `Aircraft`, enrich with route/type data, and emit snapshots.
- Location: `server/src/datasource.ts`, `server/src/enrich/`
- Contains: `Poller`, `RouteEnricher`, `lookupType`, `lookupAirline`, static JSON tables
- Depends on: `@shared` types, external HTTP APIs
- Used by: `Hub` (via `onSnapshot` / `onStatus` callbacks)
- Purpose: Load, persist, merge, and broadcast the single `Config` object.
- Location: `server/src/config-store.ts`
- Contains: `ConfigStore`
- Depends on: `@shared` `DEFAULT_CONFIG`, `mergeConfig`
- Used by: `Hub` (subscribed), `Poller` (reads via `getConfig()`), REST handlers
- Purpose: Multiplex all server → client pushes and handle client → server config commands over one WebSocket path.
- Location: `server/src/hub.ts`
- Contains: `Hub`, `WebSocketServer`
- Depends on: `ConfigStore`, snapshot/status getters from `Poller`
- Used by: Express HTTP server (shares the same `http.Server`)
- Purpose: Types and pure math shared by server and browser; the only cross-package import boundary.
- Location: `shared/src/`
- Contains: `Config`, `Aircraft`, `ServerMessage`, `ClientMessage`, `SourceStatus`, geo math (`llToMeters`, `project`, `deadReckon`, etc.)
- Depends on: nothing
- Used by: `server/`, `web/`
- Purpose: Convert live `Aircraft[]` snapshots into a smooth canvas animation via interpolation and a configurable frame-rate cap.
- Location: `web/src/display/renderer.ts`, `web/src/display/aircraftGlyph.ts`, `web/src/display/celestial.ts`, `web/src/display/stars.ts`, `web/src/display/airports.ts`
- Depends on: `@shared` types, `astronomy-engine`, `satellite.js`
- Used by: `Display` React component
- Purpose: React page shells for display and control; wire WebSocket stream to renderer or form controls.
- Location: `web/src/display/Display.tsx`, `web/src/control/Control.tsx`, `web/src/control/components.tsx`
- Depends on: `useStream`, `Renderer`, `@shared` types
- Used by: `web/src/display/main.tsx`, `web/src/control/main.tsx`
## Data Flow
### Aircraft Snapshot Path
### Config Change Path (Control Panel)
### TLE / Satellite Path
- Server: `ConfigStore` (in-memory + JSON on disk); `Poller.last` (last snapshot in memory); `Poller.sticky` (enrichment cache by ICAO hex); `RouteEnricher.cache` (disk-backed).
- Browser: `Connection.state` (plain object, subscriber pattern — not React state); lifted into React via `useState` inside `useStream`.
## Key Abstractions
- Purpose: Single shape for all data sources (dump1090, airplanes.live, adsbdb enrichment).
- Example: `shared/src/aircraft.ts`
- Pattern: Plain interface with optional fields; enrichment fields filled server-side.
- Purpose: All tuneable parameters for the ceiling tracker; persisted server-side; shared live across all clients.
- Example: `shared/src/config.ts`
- Pattern: Flat/nested plain object; mutations only via `mergeConfig()` — never direct property writes.
- Purpose: Discriminated union types for the WebSocket channel; one type per message kind.
- Example: `shared/src/messages.ts`
- Pattern: `{ type: "aircraft" | "config" | "status" }` → switch-dispatch at both ends.
- Purpose: Decoupled from React; accepts aircraft snapshots via `update()`, animates independently via rAF.
- Example: `web/src/display/renderer.ts`
- Pattern: Constructed once in `useEffect`, driven by `requestAnimationFrame`. Config read via a `getConfig()` ref so it never needs re-instantiation on config change.
- Purpose: Single auto-reconnecting socket per page; subscriber pattern for state consumers.
- Example: `web/src/lib/connection.ts`
- Pattern: Not a React context — imperative class with `subscribe(fn)` listener set, bridged into React by `useStream`.
## Entry Points
- Location: `server/src/index.ts`
- Triggers: `tsx src/index.ts` (dev) or `tsx src/index.ts` (prod via `pnpm start`)
- Responsibilities: Wire all server-side classes, register REST routes, attach WebSocket server, serve static web build, start Poller.
- Location: `web/src/display/main.tsx` → `web/index.html`
- Triggers: Browser navigating to `/` (or Vite dev server)
- Responsibilities: Mount `Display` React component; owns the fullscreen canvas for projection.
- Location: `web/src/control/main.tsx` → `web/control.html`
- Triggers: Browser navigating to `/control`
- Responsibilities: Mount `Control` React component; phone-friendly settings UI.
## Architectural Constraints
- **Threading:** Single-threaded Node.js event loop. All I/O is async (`fetch`, `fs/promises`). No worker threads. `RouteEnricher` tracks in-flight fetches via a `Map<string, Promise<void>>` to avoid duplicate requests — `server/src/enrich/routes.ts:37`.
- **Global state:** No module-level singletons on the server — all state lives in class instances wired in `server/src/index.ts`. Browser: `satrecCache` map in `web/src/display/celestial.ts:76` is the only module-level mutable state.
- **Circular imports:** None detected. Dependency direction is strict: `shared` ← `server`, `shared` ← `web`; `server` and `web` never import from each other.
- **Config ref pattern:** `Display.tsx` stores `config` in both React state (for JSX re-renders) and a plain `useRef` (so the `Renderer` rAF loop always reads the latest value without stale closures) — `web/src/display/Display.tsx:15-16`.
- **Render delay:** Renderer deliberately renders `RENDER_DELAY_MS` (1150 ms) in the past to guarantee two bracketing fixes exist for interpolation — `web/src/display/renderer.ts:32`.
## Anti-Patterns
### Bypassing `mergeConfig` for Config mutations
### Creating a new `Renderer` on config change
## Error Handling
- `fetchList` returns `null` on error, causing the Poller to emit a `status.ok = false` — `server/src/datasource.ts:162`
- `RouteEnricher` leaves entries uncached on fetch failure so they are retried on the next enrichment cycle — `server/src/enrich/routes.ts:114`
- `TleStore` logs a warning and continues using the disk cache when Celestrak is unreachable — `server/src/tle.ts:75`
- `Connection` auto-reconnects after 1.5 s on WebSocket close/error — `web/src/lib/connection.ts:67`
## Cross-Cutting Concerns
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
