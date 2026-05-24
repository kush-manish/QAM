"""
QAM Hub — Flask routes appended to QUANTFLASH Bridge (web_ui.py)
Deploy: append this file's content to web_ui.py, then docker cp + restart
"""
import uuid as _uuid
from datetime import datetime as _dt
from pathlib import Path
import json

# Requires: app, request, jsonify, _auth() already defined in web_ui.py

_QAM_DIR     = Path("/app/memory/data/qam")
_NODES_FILE  = _QAM_DIR / "nodes.json"
_QUEUE_FILE  = _QAM_DIR / "queue.json"
_MASTER_FILE = _QAM_DIR / "master.json"
_CREDITS_FILE= _QAM_DIR / "credits.json"

def _qr(p):
    try: return json.loads(p.read_text(encoding="utf-8"))
    except: return {}

def _qw(p, d):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(d, indent=2, default=str), encoding="utf-8")

def _elect():
    mesh   = _qr(_NODES_FILE)
    online = [n for n in mesh.get("nodes", {}).values() if n.get("status") == "online"]
    if not online:
        _qw(_MASTER_FILE, {"master": None, "elected_at": _dt.utcnow().isoformat()+"Z"})
        return None
    master = max(online, key=lambda n: (n.get("priority", 50), n.get("last_seen", "")))
    _qw(_MASTER_FILE, {"master": master["id"], "name": master["name"],
                        "elected_at": _dt.utcnow().isoformat()+"Z",
                        "nodes_online": len(online)})
    return master
