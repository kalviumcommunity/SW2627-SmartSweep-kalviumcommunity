"""Transactional operational rules. All timestamps are UTC Unix seconds."""

import hashlib
import hmac
import os
import secrets
import sqlite3
import time
from contextlib import contextmanager
from pathlib import Path


class Problem(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.status = status


def password_hash(password, salt=None):
    salt = salt or secrets.token_hex(16)
    digest = hashlib.scrypt(
        password.encode(), salt=salt.encode(), n=16384, r=8, p=1
    ).hex()
    return salt + ":" + digest


def text(data, key, maximum=500):
    value = data.get(key)
    if not isinstance(value, str) or not value.strip() or len(value) > maximum:
        raise Problem(f"{key} must be nonempty text (maximum {maximum} characters).")
    return value.strip()


def integer(data, key, low=1, high=10000000000):
    value = data.get(key)
    if type(value) is not int or not low <= value <= high:
        raise Problem(f"{key} must be an integer between {low} and {high}.")
    return value


class Store:
    def __init__(self, path, demo=False, delay_minutes=15, recurrence=3):
        self.path = str(path)
        self.demo = demo
        self.delay = delay_minutes * 60
        self.recurrence = recurrence
        if delay_minutes < 0 or recurrence < 2:
            raise ValueError("Delay must be nonnegative and recurrence at least 2.")
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            version = db.execute("PRAGMA user_version").fetchone()[0]
            if version not in (0, 1):
                raise ValueError(
                    f"Unsupported database version {version}; migration required."
                )
            db.executescript(Path(__file__).with_name("schema.sql").read_text())
            db.execute("INSERT OR IGNORE INTO settings VALUES ('offset','0')")
        os.chmod(self.path, 0o600)

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys=ON")
        try:
            db.execute("BEGIN IMMEDIATE")
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

    def now(self, db):
        offset = float(
            db.execute("SELECT value FROM settings WHERE key='offset'").fetchone()[0]
        )
        if offset and not self.demo:
            raise Problem(
                "This database uses a demo clock; restart with --demo or use a new database.",
                409,
            )
        return time.time() + offset

    @staticmethod
    def row(db, table, ident):
        # table is always an internal constant, never an HTTP parameter.
        row = db.execute(f"SELECT * FROM {table} WHERE id=?", (ident,)).fetchone()
        if row is None:
            raise Problem(f"{table} record not found.", 404)
        return dict(row)

    def event(self, db, route, actor, kind, now, detail):
        db.execute(
            "INSERT INTO events(route_id,actor,kind,occurred,detail) VALUES (?,?,?,?,?)",
            (route, actor, kind, now, detail),
        )

    def incident(self, db, route, kind, now, detail):
        inserted = db.execute(
            "INSERT OR IGNORE INTO incidents(route_id,kind,occurred,detail) VALUES (?,?,?,?)",
            (route, kind, now, detail),
        ).rowcount
        if inserted:
            self.event(db, route, None, kind, now, detail)

    def detect(self, db, now):
        for r in db.execute("SELECT * FROM routes WHERE verified IS NULL").fetchall():
            if now >= r["deadline"]:
                self.incident(
                    db,
                    r["id"],
                    "missed",
                    r["deadline"],
                    "Deadline passed without independently reviewed completion.",
                )
            elif r["started"] is None and now >= r["starts"] + self.delay:
                self.incident(
                    db,
                    r["id"],
                    "delayed",
                    r["starts"] + self.delay,
                    "Route has not started within the permitted window.",
                )

    def tick(self):
        with self.connect() as db:
            self.detect(db, self.now(db))

    def create_user(self, email, password, role):
        if role not in ("supervisor", "driver") or len(password) < 12:
            raise Problem("Use a valid role and a password of at least 12 characters.")
        with self.connect() as db:
            return db.execute(
                "INSERT INTO users(email,password,role) VALUES (?,?,?)",
                (email.strip().lower(), password_hash(password), role),
            ).lastrowid

    def login(self, data):
        email, password = text(data, "email", 200).lower(), text(data, "password", 256)
        with self.connect() as db:
            user = db.execute("SELECT * FROM users WHERE email=?", (email,)).fetchone()
            stored = (
                user["password"] if user else password_hash("unused-account-password")
            )
            if (
                not hmac.compare_digest(
                    password_hash(password, stored.split(":")[0]), stored
                )
                or not user
            ):
                raise Problem("Invalid email or password.", 401)
            token = secrets.token_urlsafe(32)
            db.execute("DELETE FROM sessions WHERE expires < ?", (time.time(),))
            db.execute(
                "INSERT INTO sessions VALUES (?,?,?)",
                (
                    hashlib.sha256(token.encode()).hexdigest(),
                    user["id"],
                    time.time() + 28800,
                ),
            )
            return {
                "token": token,
                "user": {
                    "id": user["id"],
                    "email": user["email"],
                    "role": user["role"],
                },
            }

    def authenticate(self, db, token):
        user = db.execute(
            "SELECT u.id,u.email,u.role FROM users u JOIN sessions s ON s.user_id=u.id WHERE s.token=? AND s.expires>?",
            (hashlib.sha256(token.encode()).hexdigest(), time.time()),
        ).fetchone()
        if not user:
            raise Problem("Please sign in again.", 401)
        return dict(user)

    @staticmethod
    def supervisor(user):
        if user["role"] != "supervisor":
            raise Problem("Supervisor access required.", 403)

    def status(self, r, now):
        if r["verified"] is not None:
            return "completed"
        if now >= r["deadline"]:
            return "missed"
        if r["interrupted"]:
            return "interrupted"
        if r["claimed"] is not None:
            return "awaiting verification"
        if r["started"] is not None:
            return "active"
        return "delayed" if now >= r["starts"] + self.delay else "scheduled"

    def snapshot(self, token, days=30):
        if not 1 <= days <= 365:
            raise Problem("Reporting period must be 1–365 days.")
        with self.connect() as db:
            user = self.authenticate(db, token)
            now = self.now(db)
            self.detect(db, now)
            routes = [
                dict(r)
                for r in db.execute(
                    """SELECT r.*,z.name zone,v.name vehicle,d.name driver,
                d.user_id driver_user_id, (SELECT COUNT(*) FROM collections c WHERE c.route_id=r.id) progress
                FROM routes r JOIN zones z ON r.zone_id=z.id JOIN vehicles v ON r.vehicle_id=v.id
                JOIN drivers d ON r.driver_id=d.id ORDER BY r.starts DESC"""
                )
            ]
            if user["role"] == "driver":
                routes = [r for r in routes if r["driver_user_id"] == user["id"]]
            ids = {r["id"] for r in routes}
            for r in routes:
                r["status"] = self.status(r, now)
            incidents = [
                dict(i)
                for i in db.execute("SELECT * FROM incidents ORDER BY occurred DESC")
                if i["route_id"] in ids
            ]
            events = [
                dict(e)
                for e in db.execute(
                    "SELECT e.*,u.email actor_email FROM events e LEFT JOIN users u ON e.actor=u.id ORDER BY e.id DESC"
                )
                if e["route_id"] in ids
            ]
            collections = [
                dict(c)
                for c in db.execute("SELECT * FROM collections")
                if c["route_id"] in ids
            ]
            zones = [dict(z) for z in db.execute("SELECT * FROM zones ORDER BY name")]
            analytics = []
            for z in zones:
                occurrences = [
                    r
                    for r in routes
                    if r["zone_id"] == z["id"]
                    and now - days * 86400 <= r["deadline"] <= now
                ]
                route_ids = {r["id"] for r in occurrences}
                missed = [
                    i
                    for i in incidents
                    if i["kind"] == "missed" and i["route_id"] in route_ids
                ]
                analytics.append(
                    {
                        "zone": z["name"],
                        "zone_id": z["id"],
                        "misses": len(missed),
                        "scheduled": len(occurrences),
                        "recurring": len(missed) >= self.recurrence,
                        "route_ids": [i["route_id"] for i in missed],
                        "recent_7_days": sum(
                            i["occurred"] >= now - 7 * 86400 for i in missed
                        ),
                        "previous_7_days": sum(
                            now - 14 * 86400 <= i["occurred"] < now - 7 * 86400
                            for i in missed
                        ),
                    }
                )
            return {
                "user": user,
                "now": now,
                "demo": self.demo,
                "days": days,
                "recurrence": self.recurrence,
                "delay_minutes": self.delay / 60,
                "routes": routes,
                "incidents": incidents,
                "collections": collections,
                "events": events,
                "zones": zones,
                "analytics": analytics,
                "vehicles": [dict(v) for v in db.execute("SELECT * FROM vehicles")],
                "drivers": [dict(d) for d in db.execute("SELECT * FROM drivers")],
                "metrics": {
                    **{
                        s: sum(r["status"] == s for r in routes)
                        for s in [
                            "scheduled",
                            "active",
                            "completed",
                            "delayed",
                            "missed",
                            "interrupted",
                            "awaiting verification",
                        ]
                    },
                    "unresolved": sum(i["resolved"] is None for i in incidents),
                },
            }

    def mutate(self, token, action, data):
        with self.connect() as db:
            user = self.authenticate(db, token)
            now = self.now(db)
            self.detect(db, now)
            uid = user["id"]
            if action == "logout":
                db.execute(
                    "DELETE FROM sessions WHERE token=?",
                    (hashlib.sha256(token.encode()).hexdigest(),),
                )
                return {}
            if action in (
                "zones",
                "vehicles",
                "drivers",
                "routes",
                "resolve",
                "repair",
                "zone-active",
                "advance",
            ):
                self.supervisor(user)
            if action == "zones":
                ident = db.execute(
                    "INSERT INTO zones(name,schedule) VALUES (?,?)",
                    (text(data, "name", 100), text(data, "schedule", 200)),
                ).lastrowid
            elif action == "zone-active":
                ident = integer(data, "id")
                self.row(db, "zones", ident)
                db.execute(
                    "UPDATE zones SET active=? WHERE id=?",
                    (integer(data, "active", 0, 1), ident),
                )
            elif action == "vehicles":
                ident = db.execute(
                    "INSERT INTO vehicles(name) VALUES (?)", (text(data, "name", 100),)
                ).lastrowid
            elif action == "drivers":
                email, password = text(data, "email", 200).lower(), text(
                    data, "password", 256
                )
                if len(password) < 12:
                    raise Problem(
                        "Driver password must contain at least 12 characters."
                    )
                driver_user = db.execute(
                    "INSERT INTO users(email,password,role) VALUES (?,?,'driver')",
                    (email, password_hash(password)),
                ).lastrowid
                ident = db.execute(
                    "INSERT INTO drivers(name,user_id) VALUES (?,?)",
                    (text(data, "name", 100), driver_user),
                ).lastrowid
            elif action == "routes":
                zone = self.row(db, "zones", integer(data, "zone_id"))
                vehicle = self.row(db, "vehicles", integer(data, "vehicle_id"))
                driver = self.row(db, "drivers", integer(data, "driver_id"))
                starts, deadline = integer(data, "starts"), integer(data, "deadline")
                if not zone["active"] or not vehicle["available"]:
                    raise Problem("Choose an active zone and available vehicle.", 409)
                if deadline <= starts or starts < now - 60:
                    raise Problem("Schedule a future start and a later deadline.")
                conflict = db.execute(
                    "SELECT id FROM routes WHERE verified IS NULL AND starts < ? AND deadline > ? AND (vehicle_id=? OR driver_id=?)",
                    (deadline, starts, vehicle["id"], driver["id"]),
                ).fetchone()
                if conflict:
                    raise Problem(
                        "Vehicle or driver already assigned in this time window.", 409
                    )
                ident = db.execute(
                    "INSERT INTO routes(name,zone_id,vehicle_id,driver_id,starts,deadline,stops,demo) VALUES (?,?,?,?,?,?,?,?)",
                    (
                        text(data, "name", 100),
                        zone["id"],
                        vehicle["id"],
                        driver["id"],
                        starts,
                        deadline,
                        integer(data, "stops", 1, 100),
                        int(self.demo),
                    ),
                ).lastrowid
                self.event(
                    db, ident, uid, "scheduled", now, "Collection occurrence scheduled."
                )
            elif action == "advance":
                if not self.demo:
                    raise Problem("Simulation is disabled.", 403)
                seconds = integer(data, "seconds", 1, 7 * 86400)
                db.execute(
                    "UPDATE settings SET value=CAST(value AS REAL)+? WHERE key='offset'",
                    (seconds,),
                )
                self.event(
                    db,
                    None,
                    uid,
                    "demo_clock",
                    now,
                    f"Demo clock advanced by {seconds} seconds.",
                )
                self.detect(db, now + seconds)
                ident = 0
            elif action == "resolve":
                incident = self.row(db, "incidents", integer(data, "id"))
                detail = text(data, "resolution")
                if incident["resolved"] is not None:
                    raise Problem("Incident already resolved.", 409)
                db.execute(
                    "UPDATE incidents SET resolved=?,resolution=? WHERE id=?",
                    (now, detail, incident["id"]),
                )
                self.event(db, incident["route_id"], uid, "resolved", now, detail)
                ident = incident["id"]
            elif action == "repair":
                ident = integer(data, "id")
                self.row(db, "vehicles", ident)
                detail = text(data, "evidence")
                db.execute("UPDATE vehicles SET available=1 WHERE id=?", (ident,))
                for r in db.execute(
                    "SELECT id FROM routes WHERE vehicle_id=? AND interrupted=1",
                    (ident,),
                ).fetchall():
                    db.execute("UPDATE routes SET interrupted=0 WHERE id=?", (r["id"],))
                    self.event(db, r["id"], uid, "vehicle_repaired", now, detail)
            elif action in ("start", "collect", "claim", "verify", "breakdown"):
                ident = integer(data, "route_id")
                r = self.row(db, "routes", ident)
                driver = self.row(db, "drivers", r["driver_id"])
                if user["role"] != "supervisor" and driver["user_id"] != uid:
                    raise Problem("This route is assigned to another driver.", 403)
                if r["verified"] is not None:
                    raise Problem("Verified routes are immutable.", 409)
                vehicle = self.row(db, "vehicles", r["vehicle_id"])
                if action == "start":
                    if (
                        r["started"] is not None
                        or now < r["starts"]
                        or not vehicle["available"]
                    ):
                        raise Problem(
                            "Route already started, not yet due, or vehicle unavailable.",
                            409,
                        )
                    occupied = db.execute(
                        "SELECT id FROM routes WHERE id!=? AND started IS NOT NULL AND verified IS NULL AND (vehicle_id=? OR driver_id=?)",
                        (ident, r["vehicle_id"], r["driver_id"]),
                    ).fetchone()
                    if occupied:
                        raise Problem(
                            "Vehicle or driver still has an unfinished started route.",
                            409,
                        )
                    db.execute("UPDATE routes SET started=? WHERE id=?", (now, ident))
                    self.event(
                        db, ident, uid, "started", now, "Route started by operator."
                    )
                elif action == "collect":
                    if (
                        r["started"] is None
                        or r["interrupted"]
                        or r["claimed"] is not None
                        or not vehicle["available"]
                    ):
                        raise Problem(
                            "Start an available route before recording collection.", 409
                        )
                    stop = integer(data, "stop", 1, r["stops"])
                    evidence = text(data, "evidence")
                    db.execute(
                        "INSERT INTO collections(route_id,stop,actor,recorded,evidence) VALUES (?,?,?,?,?)",
                        (ident, stop, uid, now, evidence),
                    )
                    self.event(
                        db,
                        ident,
                        uid,
                        "collection_reported",
                        now,
                        f"Stop {stop}: {evidence}",
                    )
                elif action == "claim":
                    count = db.execute(
                        "SELECT COUNT(*) FROM collections WHERE route_id=?", (ident,)
                    ).fetchone()[0]
                    if (
                        count != r["stops"]
                        or r["claimed"] is not None
                        or r["interrupted"]
                    ):
                        raise Problem(
                            "Record all stops on an uninterrupted route before claiming completion.",
                            409,
                        )
                    db.execute("UPDATE routes SET claimed=? WHERE id=?", (now, ident))
                    self.event(
                        db,
                        ident,
                        uid,
                        "completion_claimed",
                        now,
                        "Operator claims all collection stops complete; review required.",
                    )
                elif action == "verify":
                    self.supervisor(user)
                    self_reported = db.execute(
                        "SELECT 1 FROM collections WHERE route_id=? AND actor=?",
                        (ident, uid),
                    ).fetchone()
                    self_claimed = db.execute(
                        "SELECT 1 FROM events WHERE route_id=? AND kind='completion_claimed' AND actor=?",
                        (ident, uid),
                    ).fetchone()
                    if (
                        r["claimed"] is None
                        or self_reported
                        or self_claimed
                        or r["interrupted"]
                    ):
                        raise Problem(
                            "A different supervisor must review a complete, uninterrupted claim.",
                            409,
                        )
                    evidence = text(data, "evidence")
                    db.execute(
                        "UPDATE routes SET verified=?,verifier=? WHERE id=?",
                        (now, uid, ident),
                    )
                    self.event(db, ident, uid, "completion_verified", now, evidence)
                elif action == "breakdown":
                    if r["started"] is None or r["interrupted"]:
                        raise Problem(
                            "Breakdown requires a started, uninterrupted route.", 409
                        )
                    detail = text(data, "evidence")
                    db.execute(
                        "UPDATE vehicles SET available=0 WHERE id=?", (r["vehicle_id"],)
                    )
                    for affected in db.execute(
                        "SELECT id FROM routes WHERE vehicle_id=? AND started IS NOT NULL AND verified IS NULL",
                        (r["vehicle_id"],),
                    ).fetchall():
                        db.execute(
                            "UPDATE routes SET interrupted=1 WHERE id=?",
                            (affected["id"],),
                        )
                        self.incident(db, affected["id"], "breakdown", now, detail)
                        # One actionable breakdown thread per occurrence; reopen on recurrence.
                        db.execute(
                            "UPDATE incidents SET resolved=NULL,resolution=NULL,detail=? WHERE route_id=? AND kind='breakdown'",
                            (detail, affected["id"]),
                        )
                    self.event(db, ident, uid, "breakdown_reported", now, detail)
            else:
                raise Problem("Unknown operation.", 404)
            return {"id": ident}

    def seed(self, password):
        if not self.demo:
            raise Problem("Seed data requires --demo.")
        with self.connect() as db:
            if db.execute("SELECT 1 FROM users").fetchone():
                raise Problem("Seed refused: database already contains users.", 409)
        supervisor = self.create_user(
            "supervisor@smartsweep.local", password, "supervisor"
        )
        driver = self.create_user("driver@smartsweep.local", password, "driver")
        with self.connect() as db:
            now = self.now(db)
            db.execute(
                "INSERT INTO zones VALUES (1,'Vijay Nagar','Daily, 07:00–09:00',1)"
            )
            db.execute("INSERT INTO zones VALUES (2,'Palasia','Daily, 09:00–11:00',1)")
            db.execute("INSERT INTO vehicles VALUES (1,'Truck 01',1)")
            db.execute("INSERT INTO vehicles VALUES (2,'Truck 02',1)")
            db.execute(
                "INSERT INTO drivers VALUES (1,'Demo collection team',?)", (driver,)
            )
            # Historical fixtures are real scheduled occurrences evaluated by the detector.
            for days in (2, 5, 9):
                rid = db.execute(
                    "INSERT INTO routes(name,zone_id,vehicle_id,driver_id,starts,deadline,stops,demo) VALUES (?,1,1,1,?,?,2,1)",
                    (
                        f"Demo history {days} days ago",
                        now - days * 86400 - 3600,
                        now - days * 86400,
                    ),
                ).lastrowid
                self.event(
                    db,
                    rid,
                    supervisor,
                    "demo_seed",
                    now - days * 86400 - 3600,
                    "Synthetic historical schedule; no physical collection asserted.",
                )
            for name, zone, vehicle, start, deadline in [
                ("Morning collection", 1, 1, now - 60, now + 3600),
                ("Next collection", 2, 2, now + 7200, now + 10800),
            ]:
                rid = db.execute(
                    "INSERT INTO routes(name,zone_id,vehicle_id,driver_id,starts,deadline,stops,demo) VALUES (?,?,?,1,?,?,2,1)",
                    (name, zone, vehicle, start, deadline),
                ).lastrowid
                self.event(
                    db,
                    rid,
                    supervisor,
                    "demo_seed",
                    now,
                    "Synthetic scheduled occurrence for local demonstration.",
                )
            self.detect(db, now)
