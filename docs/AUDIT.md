# Repository audit and implementation decisions

Baseline: `1bc95efe87e67cea6bb5c6a272f7c37d6c782938`, default branch `main`. Fresh clone was clean; no user changes were overwritten. Work branch: `ai/project-completion`.

## Existing architecture

- Flutter targets Android, iOS, web, macOS, Windows and Linux, with Dart models/widgets/screens under `lib/`.
- `main.dart` initialized Firebase unconditionally. `AuthGate` routed authenticated users to `HomeScreen`; the separate `MainShell` was not the authenticated entry point.
- Firebase Auth provided login/session observation. Firestore stored owner-scoped reported issues and connection tests. Firebase Storage/image picker supported issue attachments.
- `ZoneService` provided typed Firestore queries/updates, but checked-in rules deny `zones`. There were no backend functions, relational schema, scheduler, migrations or detector.
- `RouteService`, `RouteListScreen`, `HomeScreen` metrics/alerts and route-processing demonstrations returned constants or local widget state. The README described goals as capabilities without reproducible setup.
- `Zone.missedCount` was manually incremented, with a fixed lifetime threshold of 3. It had no occurrence history or reporting-period semantics.
- The only widget test constructed the Firebase-dependent app without initializing Firebase. No operational tests existed.

## Priority decisions and actual changes

1. **Critical: no persisted operational workflow.** Added a transactional SQLite model, authenticated Python API, five-second detector and two clients sharing it. This fills a missing backend rather than replacing an existing working one.
2. **Critical: labels could imply unverified success.** Status is derived from timestamps, records and verification. Collection reports and claims are distinct from independent review. Deadline failures remain immutable historical incidents after recovery.
3. **High: no resource/authorization integrity.** Added roles, assigned-driver checks, supervisor management, separate verifier enforcement, schedule overlap checks, active-resource locks, unique collection stops and database foreign keys.
4. **High: no alerts/recurrence.** Added deduplicated incidents with response history, breakdown/repair effects, configurable grace and recurrence thresholds, and windowed per-zone analytics.
5. **High: no reproducible local setup.** Added dependency-free Python startup, safe seed/password prompt, isolated demo database, persistent simulated clock, exact local instructions and tests.
6. **High: client functionality could not be validated with native runtimes here.** Added a lightweight browser console and real-server DOM integration. Flutter remains the app technology and gains an operational API client. Chromium and Flutter execution blockers are disclosed, with portable test scripts/CI for later validation.

## Preserved and explicitly incomplete

Original Firebase code and platform projects remain. Legacy mode is opt-in and labeled; its mock reports do not participate in operational metrics. No production Firebase rules/data were changed. Legacy Firebase zones still require a separately designed access policy, and Storage/cloud behavior remains untested. There is no fake bridge between Firebase user IDs and local users.

No new production credentials, provider claims or physical GPS evidence were added. Existing Firebase client identifiers were not treated as administrator credentials or used to access production services.
