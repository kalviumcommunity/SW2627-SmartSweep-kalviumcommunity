import json
import sqlite3
import tempfile
import threading
import time
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from unittest.mock import patch
from backend.domain import Problem, Store
from backend.server import make_server

PASSWORD = "test-only-password-123"
NOW = 1800000000


class OperationsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.clock = patch("backend.domain.time.time", return_value=NOW)
        self.clock.start()
        self.path = Path(self.tmp.name) / "test.db"
        self.store = Store(self.path, demo=True)
        self.store.seed(PASSWORD)
        self.supervisor = self.store.login(
            {"email": "supervisor@smartsweep.local", "password": PASSWORD}
        )["token"]
        self.driver = self.store.login(
            {"email": "driver@smartsweep.local", "password": PASSWORD}
        )["token"]

    def tearDown(self):
        self.clock.stop()
        self.tmp.cleanup()

    def state(self):
        return self.store.snapshot(self.supervisor)

    def action(self, operation, **data):
        return self.store.mutate(self.supervisor, operation, data)

    def report(self):
        self.store.mutate(self.driver, "start", {"route_id": 4})
        for stop in (1, 2):
            self.store.mutate(
                self.driver,
                "collect",
                {
                    "route_id": 4,
                    "stop": stop,
                    "evidence": f"Collection report at stop {stop}",
                },
            )
        self.store.mutate(self.driver, "claim", {"route_id": 4})

    def test_seed_runs_real_detection_and_recurrence(self):
        s = self.state()
        self.assertEqual(s["metrics"]["missed"], 3)
        z = next(z for z in s["analytics"] if z["zone_id"] == 1)
        self.assertEqual(z["misses"], 3)
        self.assertTrue(z["recurring"])
        self.assertEqual(z["recent_7_days"], 2)
        self.assertEqual(z["previous_7_days"], 1)

    def test_never_missed_before_deadline_including_exact_boundary(self):
        self.action("advance", seconds=3599)
        self.assertNotIn(
            4,
            [i["route_id"] for i in self.state()["incidents"] if i["kind"] == "missed"],
        )
        self.action("advance", seconds=1)
        self.assertIn(
            4,
            [i["route_id"] for i in self.state()["incidents"] if i["kind"] == "missed"],
        )

    def test_delayed_window_boundary(self):
        self.action("advance", seconds=839)
        self.assertEqual(
            next(r for r in self.state()["routes"] if r["id"] == 4)["status"],
            "scheduled",
        )
        self.action("advance", seconds=1)
        self.assertEqual(
            next(r for r in self.state()["routes"] if r["id"] == 4)["status"], "delayed"
        )
        self.assertNotIn(
            4,
            [i["route_id"] for i in self.state()["incidents"] if i["kind"] == "missed"],
        )

    def test_claim_is_not_verified_completion(self):
        self.report()
        r = next(r for r in self.state()["routes"] if r["id"] == 4)
        self.assertEqual(r["status"], "awaiting verification")
        self.assertIsNone(r["verified"])
        self.action(
            "verify",
            route_id=4,
            evidence="Reviewed stop records and resident confirmation.",
        )
        self.assertEqual(
            next(r for r in self.state()["routes"] if r["id"] == 4)["status"],
            "completed",
        )

    def test_claim_without_review_still_missed(self):
        self.report()
        self.action("advance", seconds=3600)
        self.assertEqual(
            next(r for r in self.state()["routes"] if r["id"] == 4)["status"], "missed"
        )

    def test_completed_route_not_later_missed(self):
        self.report()
        self.action("verify", route_id=4, evidence="Independent review evidence")
        self.action("advance", seconds=3600)
        self.assertNotIn(
            4,
            [i["route_id"] for i in self.state()["incidents"] if i["kind"] == "missed"],
        )

    def test_late_completion_preserves_failure(self):
        self.report()
        self.action("advance", seconds=3600)
        self.action("verify", route_id=4, evidence="Late independent review")
        s = self.state()
        self.assertEqual(
            next(r for r in s["routes"] if r["id"] == 4)["status"], "completed"
        )
        self.assertEqual(
            next(z for z in s["analytics"] if z["zone_id"] == 1)["misses"], 4
        )

    def test_self_verification_rejected(self):
        self.action("start", route_id=4)
        for stop in (1, 2):
            self.action(
                "collect",
                route_id=4,
                stop=stop,
                evidence="Supervisor reported collection",
            )
        self.action("claim", route_id=4)
        with self.assertRaises(Problem):
            self.action("verify", route_id=4, evidence="Self review")

    def test_driver_cannot_verify_or_manage_or_simulate(self):
        for name in (
            "verify",
            "zones",
            "vehicles",
            "routes",
            "advance",
            "resolve",
            "repair",
            "drivers",
            "zone-active",
        ):
            with self.subTest(name=name), self.assertRaises(Problem) as raised:
                self.store.mutate(self.driver, name, {"route_id": 4})
            self.assertEqual(raised.exception.status, 403)

    def test_driver_cannot_access_another_assignment(self):
        self.action(
            "drivers", name="Other team", email="other@example.test", password=PASSWORD
        )
        token = self.store.login({"email": "other@example.test", "password": PASSWORD})[
            "token"
        ]
        self.assertEqual(self.store.snapshot(token)["routes"], [])
        with self.assertRaises(Problem) as raised:
            self.store.mutate(token, "start", {"route_id": 4})
        self.assertEqual(raised.exception.status, 403)

    def test_breakdown_is_atomic_and_deduplicated(self):
        self.action("start", route_id=4)
        self.action("breakdown", route_id=4, evidence="Engine stopped")
        s = self.state()
        self.assertEqual(
            next(r for r in s["routes"] if r["id"] == 4)["status"], "interrupted"
        )
        self.assertEqual(s["vehicles"][0]["available"], 0)
        with self.assertRaises(Problem):
            self.action("breakdown", route_id=4, evidence="Duplicate")
        with self.assertRaises(Problem):
            self.action("collect", route_id=4, stop=1, evidence="Cannot collect")
        self.assertEqual(
            len([i for i in self.state()["incidents"] if i["kind"] == "breakdown"]), 1
        )
        self.action("repair", id=1, evidence="Mechanic replaced component")
        self.action("collect", route_id=4, stop=1, evidence="Resumed collection")

    def test_repeated_breakdown_reopens_same_alert_and_retains_events(self):
        self.action("start", route_id=4)
        self.action("breakdown", route_id=4, evidence="First failure")
        incident = next(
            i for i in self.state()["incidents"] if i["kind"] == "breakdown"
        )
        self.action("resolve", id=incident["id"], resolution="Mechanic dispatched")
        self.action("repair", id=1, evidence="Repair performed")
        self.action("breakdown", route_id=4, evidence="Second failure")
        incidents = [i for i in self.state()["incidents"] if i["kind"] == "breakdown"]
        self.assertEqual(len(incidents), 1)
        self.assertIsNone(incidents[0]["resolved"])
        self.assertEqual(
            len(
                [e for e in self.state()["events"] if e["kind"] == "breakdown_reported"]
            ),
            2,
        )

    def test_active_overdue_assignment_blocks_another_start(self):
        self.action("start", route_id=4)
        self.action("advance", seconds=7200)
        with self.assertRaises(Problem):
            self.action("start", route_id=5)

    def test_resolution_does_not_erase_recurrence(self):
        incident = next(i for i in self.state()["incidents"] if i["kind"] == "missed")
        self.action("resolve", id=incident["id"], resolution="Recovery team dispatched")
        self.assertEqual(
            next(z for z in self.state()["analytics"] if z["zone_id"] == 1)["misses"], 3
        )
        self.assertEqual(self.state()["metrics"]["unresolved"], 2)

    def test_repeated_detector_does_not_duplicate_alerts(self):
        for _ in range(5):
            self.store.tick()
        self.assertEqual(len(self.state()["incidents"]), 3)

    def test_persistence_across_store_restart(self):
        self.action("start", route_id=4)
        self.action("breakdown", route_id=4, evidence="Persisted engine failure")
        self.action("advance", seconds=3600)
        before = self.state()
        self.store = Store(self.path, demo=True)
        after = self.state()
        for key in ("routes", "incidents", "events", "analytics", "metrics", "now"):
            self.assertEqual(before[key], after[key])

    def test_duplicate_stop_rolls_back_and_out_of_range_rejected(self):
        self.action("start", route_id=4)
        self.action("collect", route_id=4, stop=1, evidence="Collected")
        with self.assertRaises(sqlite3.IntegrityError):
            self.action("collect", route_id=4, stop=1, evidence="Duplicate")
        with self.assertRaises(Problem):
            self.action("collect", route_id=4, stop=3, evidence="Invalid")
        self.assertEqual(len(self.state()["collections"]), 1)

    def test_incomplete_claim_and_early_start_rejected(self):
        with self.assertRaises(Problem):
            self.action("claim", route_id=4)
        with self.assertRaises(Problem):
            self.action("start", route_id=5)

    def test_schedule_assignment_conflicts_and_invalid_input(self):
        payload = dict(
            name="New route",
            zone_id=1,
            vehicle_id=1,
            driver_id=1,
            starts=NOW + 100,
            deadline=NOW + 200,
            stops=2,
        )
        with self.assertRaises(Problem):
            self.action("routes", **payload)
        payload.update(starts=NOW + 20000, deadline=NOW + 21000)
        rid = self.action("routes", **payload)["id"]
        self.assertIn(rid, [r["id"] for r in self.state()["routes"]])
        payload.update(starts=NOW + 22000, deadline=NOW + 21000)
        with self.assertRaises(Problem):
            self.action("routes", **payload)
        with self.assertRaises(Problem):
            self.action("zones", name="", schedule="Daily")
        with self.assertRaises(Problem):
            self.action("advance", seconds=True)

    def test_inactive_zone_and_broken_vehicle_cannot_be_scheduled(self):
        payload = dict(
            name="New",
            zone_id=1,
            vehicle_id=1,
            driver_id=1,
            starts=NOW + 20000,
            deadline=NOW + 21000,
            stops=2,
        )
        self.action("zone-active", id=1, active=0)
        with self.assertRaises(Problem):
            self.action("routes", **payload)
        self.action("zone-active", id=1, active=1)
        self.action("start", route_id=4)
        self.action("breakdown", route_id=4, evidence="Failure")
        with self.assertRaises(Problem):
            self.action("routes", **payload)

    def test_reporting_window_and_configurable_recurrence(self):
        self.assertEqual(
            next(
                z
                for z in self.store.snapshot(self.supervisor, 7)["analytics"]
                if z["zone_id"] == 1
            )["misses"],
            2,
        )
        self.store = Store(self.path, demo=True, recurrence=2)
        self.assertTrue(
            next(
                z
                for z in self.store.snapshot(self.supervisor, 7)["analytics"]
                if z["zone_id"] == 1
            )["recurring"]
        )
        with self.assertRaises(Problem):
            self.store.snapshot(self.supervisor, 0)

    def test_auth_bad_password_expiration_logout_and_hash_storage(self):
        with self.assertRaises(Problem):
            self.store.login(
                {"email": "supervisor@smartsweep.local", "password": "wrong"}
            )
        with self.store.connect() as db:
            self.assertNotEqual(
                db.execute("SELECT password FROM users LIMIT 1").fetchone()[0], PASSWORD
            )
            self.assertNotEqual(
                db.execute("SELECT token FROM sessions LIMIT 1").fetchone()[0],
                self.supervisor,
            )
            db.execute("UPDATE sessions SET expires=?", (NOW - 1,))
        with self.assertRaises(Problem):
            self.state()
        token = self.store.login(
            {"email": "supervisor@smartsweep.local", "password": PASSWORD}
        )["token"]
        self.store.mutate(token, "logout", {})
        with self.assertRaises(Problem):
            self.store.snapshot(token)

    def test_demo_disabled_and_seed_non_destructive(self):
        with self.assertRaises(Problem):
            self.store.seed(PASSWORD)
        self.store = Store(self.path, demo=False)
        with self.assertRaises(Problem):
            self.action("advance", seconds=60)
        self.assertEqual(len(self.state()["routes"]), 5)

    def test_dashboard_counts_match_routes(self):
        self.action("advance", seconds=3600)
        s = self.state()
        self.assertEqual(
            sum(v for k, v in s["metrics"].items() if k != "unresolved"),
            len(s["routes"]),
        )


class HttpTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = Store(Path(self.tmp.name) / "test.db", demo=True)
        self.store.seed(PASSWORD)
        self.server = make_server(self.store, port=0)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f"http://127.0.0.1:{self.server.server_port}"

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.tmp.cleanup()

    def request(self, path, data=None, token=None):
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = "Bearer " + token
        req = Request(
            self.base + path,
            data=None if data is None else json.dumps(data).encode(),
            headers=headers,
        )
        try:
            with urlopen(req) as response:
                return response.status, json.loads(response.read())
        except HTTPError as e:
            return e.code, json.loads(e.read())

    def test_http_auth_validation_and_full_workflow(self):
        self.assertEqual(self.request("/api/health")[0], 200)
        self.assertEqual(self.request("/api/state")[0], 401)
        _, login = self.request(
            "/api/login", {"email": "supervisor@smartsweep.local", "password": PASSWORD}
        )
        token = login["token"]
        self.assertEqual(self.request("/api/state?days=bad", token=token)[0], 400)
        self.assertEqual(self.request("/api/start", {"route_id": 4}, token)[0], 200)
        self.assertEqual(
            self.request(
                "/api/breakdown", {"route_id": 4, "evidence": "Engine failure"}, token
            )[0],
            200,
        )
        self.assertEqual(
            self.request(
                "/api/breakdown", {"route_id": 4, "evidence": "Duplicate"}, token
            )[0],
            409,
        )
        status, state = self.request("/api/state", token=token)
        self.assertEqual(status, 200)
        self.assertEqual(
            len([i for i in state["incidents"] if i["kind"] == "breakdown"]), 1
        )
        self.assertEqual(self.request("/api/logout", {}, token)[0], 200)
        self.assertEqual(self.request("/api/state", token=token)[0], 401)

    def test_http_bad_bodies_static_assets_and_rate_limit(self):
        for body in ([], None, 123):
            req = Request(
                self.base + "/api/login",
                data=json.dumps(body).encode(),
                headers={"Content-Type": "application/json"},
            )
            with self.assertRaises(HTTPError) as raised:
                urlopen(req)
            self.assertEqual(raised.exception.code, 400)
        with urlopen(self.base + "/") as response:
            self.assertIn(b"SmartSweep", response.read())
        for _ in range(15):
            self.request(
                "/api/login", {"email": "unknown@example.test", "password": "bad"}
            )
        self.assertEqual(
            self.request(
                "/api/login", {"email": "unknown@example.test", "password": "bad"}
            )[0],
            429,
        )


if __name__ == "__main__":
    unittest.main()
