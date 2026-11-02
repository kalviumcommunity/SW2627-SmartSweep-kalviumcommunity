# Operational architecture and API

## Data flow

Flutter `OperationsScreen` / browser console → authenticated JSON HTTP API → SQLite transaction → collection events, incidents and derived state. A server thread checks deadlines every five seconds. Reads also run the same idempotent detector before returning a consistent snapshot. Clients poll every five seconds.

`backend/schema.sql` initializes schema version 1 automatically; later unknown versions fail explicitly. Foreign keys, check constraints, unique stop records and unique incident threads enforce integrity. Writes use `BEGIN IMMEDIATE`, serializing concurrent decisions. Passwords use salted scrypt. Only SHA-256 digests of random session tokens are stored. Sessions expire after eight hours using real wall time, unaffected by demo clock advances. Tokens are held in Flutter memory or browser tab sessionStorage.

The single local organization has supervisor and driver roles. Drivers see only their assigned routes/records and cannot manage inventory, resolve incidents, verify completion or advance the clock. Fleet/zone/team names are shared local reference data. There is no public signup; supervisors create team accounts and the CLI creates supervisors.

## Endpoints

All responses are JSON. Errors use `{ "error": "message" }` with 400 validation, 401 authentication, 403 authorization, 404 missing record, 409 conflicting state, 413 oversized body, 415 wrong content type or 429 login throttling. POST requires JSON. Maximum request body is 16 KiB. Except health/login, pass `Authorization: Bearer <token>`.

| Method/path | Body / behavior |
|---|---|
| GET `/api/health` | Service status and demo flag |
| POST `/api/login` | `email`, `password`; returns token and role |
| POST `/api/logout` | `{}`; revokes current session |
| GET `/api/state?days=30` | Snapshot: routes, collections, incidents, events, inventory, metrics and analytics; days 1–365 |
| POST `/api/zones` | Supervisor: `name`, `schedule` description |
| POST `/api/zone-active` | Supervisor: zone `id`, `active` (0/1); does not cancel existing schedules |
| POST `/api/vehicles` | Supervisor: `name` |
| POST `/api/drivers` | Supervisor: `name`, `email`, `password` (12+ characters) |
| POST `/api/routes` | Supervisor: `name`, `zone_id`, `vehicle_id`, `driver_id`, `starts`, `deadline` (integer UTC epoch seconds), `stops` (1–100) |
| POST `/api/start` | Assigned driver/supervisor: `route_id` |
| POST `/api/collect` | Assigned driver/supervisor: `route_id`, `stop`, nonempty `evidence` |
| POST `/api/claim` | Assigned driver/supervisor: `route_id`; all stops must exist |
| POST `/api/verify` | Different supervisor: `route_id`, review `evidence`; reporter and claimant cannot self-verify |
| POST `/api/breakdown` | Assigned driver/supervisor: `route_id`, `evidence`; unavailable vehicle and interrupted started routes |
| POST `/api/repair` | Supervisor: vehicle `id`, repair `evidence`; restores availability, clears interruption, retains incidents |
| POST `/api/resolve` | Supervisor: incident `id`, `resolution`; retains failure and appends response event |
| POST `/api/advance` | Supervisor/demo only: `seconds` (1–604800); persists demo time offset and evaluates detector |

Route occurrences use absolute timestamps. The zone schedule is a human-readable template description, not a cron expression. Recurrence counts distinct missed route occurrences whose deadlines are within `[operational_now - days, operational_now]`. Trend buckets are clipped to the selected reporting period. No percentages silently substitute for recorded evidence.

Current route status precedence: verified completion → missed deadline → interrupted → awaiting verification → active → delayed → scheduled. Thus historical incident counts can exceed the number of routes currently labeled missed: late verified recovery changes current status, not incident history.

## Future tracking adapter

A real driver/telematics integration can authenticate as an assigned operator and submit timestamped start/collection/breakdown reports through these endpoints. Server receive time is authoritative; client clocks cannot backdate completion or suppress a miss. Stop IDs are stable occurrence-local integers. This interface currently accepts text evidence only; future GPS/photo inputs need provenance, upload limits and retention design. Vehicle passage alone must not call `collect` or `verify` automatically.

## Deployment boundary

Loopback HTTP is suitable for local demonstration. Before remote deployment: replace/harden the HTTP serving layer, enforce TLS, add organization scoping, pagination, backups, account lifecycle/recovery, observability and a supervised detector process. SQLite time and transactions are authoritative only while this server controls writes. Do not run with real production data or expose this standard-library server to the internet.
