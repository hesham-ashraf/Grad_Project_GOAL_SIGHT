"""API-layer verification (no model needed).

Exercises the full job lifecycle through FastAPI's TestClient with the model
absent, so we confirm routing, schemas, the job state machine, and graceful
error propagation. The model itself is verified separately on the GPU host.
"""
import os
import time

# Point at a model dir that does NOT exist so the worker fails fast & cleanly.
os.environ["GOALSIGHT_MODEL_DIR"] = os.path.abspath("./_no_model_here")
os.environ["GOALSIGHT_DEVICE"] = "cpu"

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

c = TestClient(app)
ok = True


def check(label, cond):
    global ok
    print(f"  [{'PASS' if cond else 'FAIL'}] {label}")
    ok = ok and cond


print("== /health ==")
r = c.get("/health")
check("health 200", r.status_code == 200)
check("health reports model absent", r.json().get("model_present") is False)

print("== POST /jobs (multipart) ==")
r = c.post(
    "/jobs",
    files={"video": ("clip.mp4", b"\x00\x01\x02not-a-real-video", "video/mp4")},
    data={"home_team": "AlAhly", "away_team": "Zamalek", "competition": "EPL"},
)
check("create 200", r.status_code == 200)
job_id = r.json().get("job_id")
check("returned job_id", bool(job_id))
check("status queued/detecting", r.json().get("status") in ("queued", "detecting"))

print("== GET /jobs/{id} polling -> should end 'failed' (model missing) ==")
final = None
for _ in range(50):
    s = c.get(f"/jobs/{job_id}").json()
    final = s["status"]
    if final in ("failed", "completed", "awaiting_naming"):
        break
    time.sleep(0.2)
check("reached terminal state", final in ("failed", "awaiting_naming", "completed"))
check("failed cleanly (model absent)", final == "failed")
errtext = c.get(f"/jobs/{job_id}").json().get("error") or ""
check("error mentions model dir", "MODEL_DIR" in errtext or "model" in errtext.lower())

print("== state guards ==")
check("naming 409 before ready", c.get(f"/jobs/{job_id}/naming").status_code == 409)
check("result 409 before ready", c.get(f"/jobs/{job_id}/result").status_code == 409)
check("unknown job 404", c.get("/jobs/does-not-exist").status_code == 404)
check(
    "confirm-players rejects bad team",
    c.post(f"/jobs/{job_id}/players",
           json={"mappings": [], "my_team_id": 5}).status_code in (400, 409),
)

print("\nRESULT:", "ALL API CHECKS PASSED" if ok else "SOME CHECKS FAILED")
raise SystemExit(0 if ok else 1)
