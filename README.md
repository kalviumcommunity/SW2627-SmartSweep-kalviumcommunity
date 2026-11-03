# SmartSweep

SmartSweep helps waste collection supervisors detect missed deadlines and breakdowns, review collection reports, and identify repeated failures in residential zones.

The reliable local path is a **Python/SQLite operational API plus a browser console**. The existing Flutter application now defaults to an operational client for the same API. Original Firebase authentication, issue/image storage and learning screens are preserved behind an explicit legacy flag. The two data stores are **separate**; there is no implicit Firebase/SQLite synchronization.

**Validation status:** backend/API tests and the browser console's DOM integration pass. Native Flutter and Chromium execution were blocked by the implementation sandbox; their build/rendering results are **not verified**. See [verification evidence](docs/VERIFICATION.md), [audit](docs/AUDIT.md), and [API/architecture](docs/ARCHITECTURE.md). This is a local demonstration implementation, not a production deployment.

## Run the local demonstration

Requires **Python 3.10+** (tested with 3.12.14). No Python dependencies, cloud account, API keys, database server, or Node installation are required to run the console.

From the repository root:

```bash
python3 -m backend.server --demo --seed
```

At the prompt, choose your own password of at least 12 characters. The seed creates:

- `supervisor@smartsweep.local` — supervisor
- `driver@smartsweep.local` — collection operator

Both use the password you chose. Passwords are salted/scrypt-hashed; no built-in password is committed. Open **http://127.0.0.1:8080**. The schema initializes automatically in `data/smartsweep.db` (ignored by Git). Demo seeding refuses to overwrite a database containing users.

On subsequent runs, preserve the same database and omit `--seed`:

```bash
python3 -m backend.server --demo
```

The demo clock offset and all records persist across restarts. To create a separate fresh demo without deleting anything:

```bash
python3 -m backend.server --demo --seed --db data/another-demo.db --port 8081
```

Optional environment variables are documented in `.env.example`; the server does not automatically load `.env`. `SMARTSWEEP_PASSWORD` can supply a password noninteractively, but the interactive prompt avoids exposing it in shell history. The service binds to loopback only.

## Demonstrate the complete workflow

1. Sign in as the **supervisor**. See two current/future schedules and three historical synthetic missed occurrences in Vijay Nagar. These are persisted fixtures evaluated by the same detector as new schedules; they are labeled demo records.
2. In **Zones & fleet**, create a zone (with schedule description), vehicle and driver/team account. Schedule a dated collection occurrence with a start, deadline and number of stops. Select an available vehicle and team; overlapping assignments are rejected. Schedule descriptions do not automatically generate future occurrences: explicitly schedule each date.
3. In another browser profile/incognito window, sign in as **driver@smartsweep.local**. Start **Morning collection**, record each stop with a description of collection evidence, and claim completion. The route becomes **awaiting verification**, not completed.
4. As supervisor, refresh or wait up to five seconds. Read the recorded evidence, then **Review & verify** with independent review notes. The reporting/claiming user cannot verify their own work. Verification means documented human review; it is not proof from GPS hardware.
5. To demonstrate a breakdown, use a fresh demo or another assigned route: start it and choose **Report breakdown**, giving incident details. The vehicle becomes unavailable, the route is interrupted, and one in-app alert is created. Other sessions receive it through polling within five seconds under normal local conditions.
6. In **Zones & fleet**, **Record repair** to restore vehicle availability. In **Alerts**, record a response separately. Resolving an alert does not erase the incident or imply that collection happened. A subsequent breakdown on the same occurrence reopens its existing alert and appends another event.
7. On an unverified route, use **Simulate +2 hours** to advance the persisted demo clock. Once its deadline is reached, the detector records a miss. Before the deadline it may be delayed or interrupted, but never missed. The detector also runs every five real seconds while the server is alive, without requiring an open dashboard.
8. In **Analytics & history**, select 7/30/90/365 days. A recurring zone has at least **3 missed occurrences** in that period, using scheduled deadlines. See affected route IDs, due counts, recent/prior seven-day counts and event history. Late recovery and alert resolution do not erase historical misses.
9. Reload the page or restart the server without `--seed`. Operational data remains. Browser sessions persist in that tab until expiry/logout; Flutter intentionally requires login after restarting its client.

If you use the supervisor account to report collection, a **different supervisor account** must review it. Create one with the server CLI (stop the existing server first if using the same port):

```bash
python3 -m backend.server --demo --create-supervisor reviewer@smartsweep.local
```

## Detection and completion rules

- **Delayed:** not started at scheduled start + configurable grace, but before deadline. Default grace: 15 minutes.
- **Missed:** deadline reached without independently reviewed completion. A fully reported but unreviewed claim is still missed under this policy.
- **Interrupted:** a started, unverified route has a reported breakdown before its deadline. After its deadline the primary status becomes missed; the breakdown incident remains.
- **Completed:** all stops reported, completion claimed, and a different supervisor recorded review evidence. A late completion can be completed now while retaining its historical miss.
- One delay, miss and actionable breakdown thread per route occurrence prevents polling/retry duplicates. Repeated breakdown reports after repair remain in the event log and reopen that thread.
- Stale active routes retain their team/vehicle lock until completion; an overdue route cannot silently release an occupied resource.
- Dashboard counts cover all stored route occurrences. Analytics alone uses the selected reporting window.

Configure thresholds on startup:

```bash
python3 -m backend.server --demo --delay-minutes 20 --recurrence 3
```

Keep thresholds consistent across restarts: previously recorded incidents are immutable history and are not retracted if thresholds change.

## Flutter client

Existing stack: Flutter/Dart, `http`, Firebase Auth, Firestore, Firebase Storage and image picker. `pubspec.yaml` requires Dart `^3.13.5`; the downloaded Flutter 3.47.9 SDK contains Dart 3.13.7. These versions matched the repository, but Dart could not initialize in the implementation sandbox.

The following Flutter commands are provided for a normal development machine. **`flutter pub get` was attempted and blocked during tool bootstrap; analyze, tests, run and build therefore remain unverified**:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run -d chrome --web-port 3000 --dart-define=API_URL=http://127.0.0.1:8080
flutter build web --dart-define=API_URL=http://127.0.0.1:8080
```

Run the Python API in another terminal first. CORS permits `localhost:3000` and `127.0.0.1:3000`. For a built web client, the API can serve the build from the same origin:

```bash
python3 -m backend.server --demo --web build/web
```

Android emulator clients normally require `API_URL=http://10.0.2.2:8080`, but the local server is intentionally loopback-only. Mobile/device networking, platform HTTP policy and release builds have not been validated; use the browser console for the verified local path.

To inspect the original Firebase prototype deliberately:

```bash
flutter run --dart-define=LEGACY_FIREBASE=true
```

That mode initializes the original Firebase project and is visibly labeled **LEGACY PROTOTYPE**. It retains the original mock route screens and independent issue storage. It is not part of the completed operational workflow. Existing Firestore rules still deny the legacy zone collection, and existing Storage permissions/cloud configuration require separate review. No production Firebase data or permissions were changed.

## Tests

Backend/domain/HTTP tests (verified):

```bash
python3 -m unittest discover -s backend/tests -v
python3 -m compileall -q backend
```

Console script checks and DOM integration, using a real temporary SQLite database and HTTP server (verified; requires Node 20.19+):

```bash
npm ci
node --check backend/web/app.js
npm run test:console
```

Real browser rendering/e2e test (implemented, **blocked in this sandbox**):

```bash
npx playwright install chromium
npm run test:e2e
```

The browser test creates a fresh temporary database and random password, exercises supervisor and driver sessions, and writes ignored screenshots to `test-results/`. `CHROMIUM_PATH` optionally selects a system browser. It never uses your local demo database. The DOM test verifies actual forms/API behavior but does not validate rendering, accessibility-tree behavior or browser layout.

GitHub Actions configuration runs backend, DOM, browser and Flutter validation once the branch can be pushed. No successful CI run is claimed.

## Scope and limitations

- SQLite and the standard-library HTTP server are intended for a small, local demo. Production hosting, TLS, backups, multi-tenant scoping, account recovery and deployment hardening remain future work.
- No GPS, geofencing, vehicle hardware, SMS, WhatsApp, email, push notifications or photo evidence integration is implemented for operations. In-app alerts work through polling.
- The record/report endpoints are the integration boundary for a future authenticated driver or hardware adapter. Proximity must never be translated automatically into collection evidence.
- Zones have schedule descriptions plus explicitly dated route occurrences; automatic recurring calendar expansion, route optimization and map navigation are not implemented.
- Recurrence is calculated from durable missed-incident records, not editable counters. Misses include unverified completion at deadline, so operational policy must account for review staffing.
- Historical lists are unpaginated. This is appropriate for the local demonstration dataset, not a large fleet archive.
- Full Flutter build/device testing and real-browser validation remain required before claiming the Flutter client works end to end or deploying this publicly.
## Final Sprint Review

SmartSweep documentation has been reviewed and updated for the final sprint submission. The project includes Firebase Authentication, Firestore, security rules, storage, persistent login, and search/filtering features.
cat >> README.md <<'EOF'

## Final Sprint Review

SmartSweep documentation has been reviewed and updated for the final sprint submission. The project includes Firebase Authentication, Firestore, security rules, storage, persistent login, and search/filtering features.
EOF