#!/usr/bin/env python3
"""Synthetic Auth/PostgREST/Storage/Functions/Realtime smoke checks.

Run only with a private staging config containing SUPABASE_URL,
SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY. This runner refuses every
project except the approved Everywear staging ref and creates/deletes only
synthetic accounts and rows.
"""

from __future__ import annotations

import base64
import json
import os
import pathlib
import secrets
import stat
import subprocess
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request
import uuid


EXPECTED_REF = "aftdbphdobfrshienple"
EXPECTED_URL = f"https://{EXPECTED_REF}.supabase.co"


class CheckFailure(RuntimeError):
    pass


def request(
    method: str,
    url: str,
    headers: dict[str, str],
    body: object | bytes | None = None,
) -> tuple[int, bytes]:
    encoded: bytes | None
    request_headers = dict(headers)
    if isinstance(body, bytes):
        encoded = body
    elif body is None:
        encoded = None
    else:
        encoded = json.dumps(body, separators=(",", ":")).encode()
        request_headers.setdefault("Content-Type", "application/json")
    req = urllib.request.Request(
        url, data=encoded, headers=request_headers, method=method
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def parse_json(status: int, raw: bytes, label: str) -> object:
    if not 200 <= status < 300:
        raise CheckFailure(f"{label}: HTTP {status}")
    try:
        return json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise CheckFailure(f"{label}: invalid JSON response") from None


class StagingSmoke:
    def __init__(self, config: dict[str, str]):
        self.url = config["SUPABASE_URL"].rstrip("/")
        self.anon = config["SUPABASE_ANON_KEY"]
        self.service = config["SUPABASE_SERVICE_ROLE_KEY"]
        self.results: list[tuple[str, bool]] = []
        self.users: list[dict[str, str]] = []
        self.deleted_users: set[str] = set()
        self.uploaded_objects: list[tuple[str, str]] = []

    def check(self, label: str, passed: bool) -> None:
        self.results.append((label, bool(passed)))
        if not passed:
            raise CheckFailure(label)

    def headers(self, token: str | None = None, *, admin: bool = False):
        key = self.service if admin else self.anon
        return {
            "apikey": key,
            "Authorization": f"Bearer {token or key}",
            "Content-Type": "application/json",
        }

    def auth_admin(self, uid: str) -> tuple[int, bytes]:
        return request(
            "DELETE",
            f"{self.url}/auth/v1/admin/users/{uid}",
            self.headers(admin=True),
        )

    def create_user(self, label: str) -> dict[str, str]:
        email = f"everywear-staging-{label}-{uuid.uuid4().hex}@example.invalid"
        password = secrets.token_urlsafe(24)
        status, raw = request(
            "POST",
            f"{self.url}/auth/v1/admin/users",
            self.headers(admin=True),
            {"email": email, "password": password, "email_confirm": True},
        )
        user = parse_json(status, raw, f"create synthetic user {label}")
        uid = user.get("id") if isinstance(user, dict) else None
        self.check(f"create synthetic user {label}", isinstance(uid, str))
        result = {"id": uid, "email": email, "password": password}
        self.users.append(result)
        session_status, session_raw = request(
            "POST",
            f"{self.url}/auth/v1/token?grant_type=password",
            {"apikey": self.anon, "Content-Type": "application/json"},
            {"email": email, "password": password},
        )
        session = parse_json(session_status, session_raw, f"sign in {label}")
        token = session.get("access_token") if isinstance(session, dict) else None
        refresh = session.get("refresh_token") if isinstance(session, dict) else None
        if not isinstance(token, str) or not isinstance(refresh, str):
            raise CheckFailure(f"sign in {label}: session missing")
        result.update({"token": token, "refresh": refresh})
        self.check(f"password sign-in {label}", True)
        return result

    def rest(
        self,
        user: dict[str, str] | None,
        method: str,
        path: str,
        body: object | bytes | None = None,
        *,
        admin: bool = False,
        extra_headers: dict[str, str] | None = None,
    ) -> tuple[int, bytes]:
        token = user["token"] if user else None
        headers = self.headers(token, admin=admin)
        headers.update(extra_headers or {})
        return request(method, f"{self.url}/{path.lstrip('/')}", headers, body)

    def table(
        self,
        user: dict[str, str] | None,
        table: str,
        query: str,
        method: str = "GET",
        body: object | None = None,
        *,
        admin: bool = False,
    ) -> tuple[int, bytes]:
        return self.rest(
            user,
            method,
            f"rest/v1/{table}?{query}",
            body,
            admin=admin,
            extra_headers={"Prefer": "return=representation"},
        )

    def profile_checks(self, a: dict[str, str], b: dict[str, str]) -> None:
        uid_a, uid_b = a["id"], b["id"]
        status, _ = self.table(None, "user_profiles", "select=id")
        self.check("anonymous profile read is denied",
                   not 200 <= status < 300)
        status, _ = self.table(None, "subscription_transactions", "select=id")
        self.check("anonymous billing history read is denied",
                   not 200 <= status < 300)
        status, raw = self.table(None, "wardrobe_items", "select=id")
        rows = parse_json(status, raw, "anonymous wardrobe read")
        self.check("anonymous cannot see wardrobe rows",
                   isinstance(rows, list) and not rows)

        status, raw = self.table(
            a, "user_profiles", f"id=eq.{uid_a}&select=id,full_name,tier"
        )
        profile = parse_json(status, raw, "user A reads own profile")
        self.check("user A reads own profile", isinstance(profile, list) and
                   len(profile) == 1 and profile[0]["id"] == uid_a)

        status, raw = self.table(
            b, "user_profiles", f"id=eq.{uid_a}&select=id"
        )
        rows = parse_json(status, raw, "user B cross-profile read")
        self.check("user B cannot read user A profile",
                   isinstance(rows, list) and not rows)

        status, raw = self.table(
            a,
            "user_profiles",
            f"id=eq.{uid_a}",
            "PATCH",
            {"full_name": "Synthetic staging user A"},
        )
        result = parse_json(status, raw, "legitimate profile update")
        self.check("legitimate profile update succeeds",
                   isinstance(result, list) and len(result) == 1)

        for column, value in (
            ("tier", "premium"),
            ("subscription_status", "active"),
            ("subscription_expires_at", "2099-01-01T00:00:00Z"),
            ("items_limit", 999999),
            ("items_count", 999999),
            ("monthly_suggestions_used", 0),
            ("daily_suggestions_used", 0),
            ("coaching_sessions_used", 0),
            ("revenue_cat_id", "forged-staging-id"),
        ):
            status, _ = self.table(
                a, "user_profiles", f"id=eq.{uid_a}", "PATCH", {column: value}
            )
            self.check(f"client cannot update protected profile {column}",
                       not 200 <= status < 300)

        status, _ = self.rest(
            None,
            "POST",
            "rest/v1/rpc/upgrade_user_to_premium",
            {"user_uuid": uid_a},
        )
        self.check("anonymous self-upgrade RPC is denied",
                   not 200 <= status < 300)
        status, _ = self.rest(
            a,
            "POST",
            "rest/v1/rpc/upgrade_user_to_premium",
            {"user_uuid": uid_a},
        )
        self.check("authenticated self-upgrade RPC is denied",
                   not 200 <= status < 300)

        status, _ = self.table(
            a,
            "ai_usage_buckets",
            f"user_id=eq.{uid_a}",
            "PATCH",
            {"month_used": 0},
        )
        self.check("client cannot edit AI counters",
                   not 200 <= status < 300)

        status, raw = request(
            "PUT",
            f"{self.url}/auth/v1/user",
            self.headers(a["token"]),
            {"data": {"tier": "premium",
                      "subscription_expires_at": "2099-01-01T00:00:00Z"}},
        )
        metadata = parse_json(status, raw, "forged user metadata update")
        self.check("user metadata update is limited to untrusted metadata",
                   isinstance(metadata, dict))
        status, raw = self.rest(a, "POST", "rest/v1/rpc/get_ai_allowance", {})
        allowance = parse_json(status, raw, "server AI allowance")
        self.check("forged metadata resolves to free tier",
                   isinstance(allowance, dict) and allowance.get("tier") == "free"
                   and allowance.get("month_limit") == 20)

        status, raw = request(
            "POST",
            f"{self.url}/auth/v1/token?grant_type=refresh_token",
            {"apikey": self.anon, "Content-Type": "application/json"},
            {"refresh_token": a["refresh"]},
        )
        refreshed = parse_json(status, raw, "session restoration")
        self.check("refresh token restores the same account",
                   isinstance(refreshed, dict) and
                   refreshed.get("user", {}).get("id") == uid_a)
        if isinstance(refreshed, dict) and isinstance(refreshed.get("access_token"), str):
            a["token"] = refreshed["access_token"]

    def wardrobe_checks(self, a: dict[str, str], b: dict[str, str]) -> str:
        uid_a, uid_b = a["id"], b["id"]

        def create_item(user: dict[str, str], owner_id: str, name: str) -> str:
            status, raw = self.table(
                user,
                "wardrobe_items",
                "select=id,user_id",
                "POST",
                {"user_id": owner_id, "name": name, "category": "Tops"},
            )
            rows = parse_json(status, raw, f"insert synthetic {name}")
            if not isinstance(rows, list) or len(rows) != 1:
                raise CheckFailure(f"insert synthetic {name}: no row")
            return rows[0]["id"]

        item_a = create_item(a, uid_a, "Synthetic item A")
        item_b = create_item(b, uid_b, "Synthetic item B")
        self.check("owner can create wardrobe items", bool(item_a and item_b))

        status, raw = self.table(
            b, "wardrobe_items", f"id=eq.{item_a}&select=id"
        )
        rows = parse_json(status, raw, "cross-account wardrobe read")
        self.check("user B cannot read user A wardrobe item",
                   isinstance(rows, list) and not rows)

        status, _ = self.table(
            b,
            "wardrobe_items",
            "select=id",
            "POST",
            {"user_id": uid_a, "name": "forged owner", "category": "Tops"},
        )
        self.check("user B cannot insert into user A wardrobe",
                   not 200 <= status < 300)

        status, raw = self.table(
            a,
            "outfit_logs",
            "select=id",
            "POST",
            {"user_id": uid_a, "outfit_name": "Synthetic outfit A"},
        )
        outfits = parse_json(status, raw, "create synthetic outfit")
        outfit_a = outfits[0]["id"] if isinstance(outfits, list) and outfits else None
        self.check("owner can create outfit", isinstance(outfit_a, str))
        status, _ = self.table(
            a,
            "outfit_items",
            "select=id",
            "POST",
            {"outfit_id": outfit_a, "item_id": item_a},
        )
        rows = parse_json(status, _, "link owned outfit and item")
        self.check("owner can link own outfit and wardrobe item",
                   isinstance(rows, list) and len(rows) == 1)
        status, _ = self.table(
            a,
            "outfit_items",
            "select=id",
            "POST",
            {"outfit_id": outfit_a, "item_id": item_b},
        )
        self.check("outfit link to another user's item is denied",
                   not 200 <= status < 300)
        return item_a

    def quota_checks(self, a: dict[str, str], b: dict[str, str]) -> None:
        status, raw = self.rest(None, "POST", "rest/v1/rpc/get_ai_allowance", {})
        self.check("anonymous quota read is denied", not 200 <= status < 300)
        status, raw = self.rest(
            a, "POST", "rest/v1/rpc/get_ai_allowance", {}
        )
        allowance = parse_json(status, raw, "read free allowance")
        self.check("free allowance is server-derived",
                   isinstance(allowance, dict) and allowance.get("tier") == "free"
                   and allowance.get("month_limit") == 20
                   and allowance.get("day_limit") == 3
                   and allowance.get("burst_limit") == 1)

        request_ids = [str(uuid.uuid4()), str(uuid.uuid4())]
        responses: list[tuple[int, bytes] | None] = [None, None]

        def reserve(index: int) -> None:
            responses[index] = self.rest(
                a,
                "POST",
                "rest/v1/rpc/reserve_ai_action",
                {"p_request_id": request_ids[index],
                 "p_action_name": "style-coach"},
            )

        threads = [threading.Thread(target=reserve, args=(i,)) for i in range(2)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(timeout=25)
        self.check("concurrent quota requests completed",
                   all(not thread.is_alive() for thread in threads))
        parsed = [
            parse_json(status, raw, "concurrent reservation")
            for response in responses
            if response is not None
            for status, raw in [response]
        ]
        allowed = [i for i, result in enumerate(parsed)
                   if isinstance(result, dict) and result.get("allowed") is True]
        self.check("atomic burst reservation admits at most one request",
                   len(parsed) == 2 and len(allowed) == 1)

        winner_id = request_ids[allowed[0]]
        status, raw = self.rest(
            a,
            "POST",
            "rest/v1/rpc/reserve_ai_action",
            {"p_request_id": winner_id, "p_action_name": "analyze-clothing"},
        )
        replay = parse_json(status, raw, "cross-endpoint request replay")
        self.check("request replay is denied across endpoint names",
                   isinstance(replay, dict) and replay.get("allowed") is False
                   and replay.get("reason") == "duplicate")

        status, raw = self.rest(
            b,
            "POST",
            "rest/v1/rpc/get_ai_allowance",
            {},
        )
        allowance_b = parse_json(status, raw, "user B independent allowance")
        self.check("quota counters are isolated by user",
                   isinstance(allowance_b, dict) and
                   allowance_b.get("month_used") == 0)

    def storage_checks(self, a: dict[str, str], b: dict[str, str]) -> list[tuple[str, str]]:
        uid_a = a["id"]
        suffix = uuid.uuid4().hex
        objects = [
            ("wardrobe-images", f"{uid_a}/smoke/{suffix}.jpg"),
            ("avatars", f"{uid_a}/smoke/{suffix}-avatar.jpg"),
        ]
        image = b"Synthetic staging image; not a customer photo."
        for bucket, path in objects:
            status, _ = self.rest(
                a,
                "POST",
                f"storage/v1/object/{bucket}/{path}",
                image,
                extra_headers={"Content-Type": "image/jpeg"},
            )
            self.check(f"owner uploads private {bucket} object",
                       200 <= status < 300)
            self.uploaded_objects.append((bucket, path))

            status, raw = self.rest(
                a, "GET", f"storage/v1/object/authenticated/{bucket}/{path}"
            )
            self.check(f"owner reads {bucket} object",
                       200 <= status < 300 and raw == image)

            status, _ = self.rest(
                b, "GET", f"storage/v1/object/authenticated/{bucket}/{path}"
            )
            self.check(f"other user cannot read {bucket} object",
                       not 200 <= status < 300)

            status, _ = self.rest(
                None, "GET", f"storage/v1/object/public/{bucket}/{path}"
            )
            self.check(f"anonymous cannot read {bucket} object",
                       not 200 <= status < 300)

            status, _ = self.rest(
                b,
                "POST",
                f"storage/v1/object/{bucket}/{path}",
                b"forged replacement",
                extra_headers={"Content-Type": "image/jpeg", "x-upsert": "true"},
            )
            self.check(f"other user cannot replace {bucket} object",
                       not 200 <= status < 300)

            status, raw = self.rest(
                a,
                "POST",
                f"storage/v1/object/sign/{bucket}/{path}",
                {"expiresIn": 60},
            )
            signed = parse_json(status, raw, f"sign {bucket} object")
            self.check(f"owner can obtain authorized {bucket} URL",
                       isinstance(signed, dict) and
                       isinstance(signed.get("signedURL"), str))

            status, _ = self.rest(
                b,
                "POST",
                f"storage/v1/object/sign/{bucket}/{path}",
                {"expiresIn": 60},
            )
            self.check(f"other user cannot sign {bucket} object",
                       not 200 <= status < 300)

            status, _ = self.rest(
                a,
                "POST",
                f"storage/v1/object/{bucket}/{path}",
                image + b" replacement",
                extra_headers={"Content-Type": "image/jpeg", "x-upsert": "true"},
            )
            self.check(f"owner can replace {bucket} object",
                       200 <= status < 300)

        delete_path = f"{uid_a}/smoke/{suffix}-delete.jpg"
        status, _ = self.rest(
            a,
            "POST",
            f"storage/v1/object/wardrobe-images/{delete_path}",
            image,
            extra_headers={"Content-Type": "image/jpeg"},
        )
        self.check("owner uploads direct-delete fixture", 200 <= status < 300)
        self.uploaded_objects.append(("wardrobe-images", delete_path))
        status, _ = self.rest(
            a,
            "DELETE",
            "storage/v1/object/wardrobe-images",
            {"prefixes": [delete_path]},
        )
        self.check("owner can directly delete own image", 200 <= status < 300)
        status, _ = self.rest(
            a,
            "GET",
            f"storage/v1/object/authenticated/wardrobe-images/{delete_path}",
        )
        self.check("directly deleted image is unavailable",
                   not 200 <= status < 300)

        profile_ref = f"avatars/{objects[1][1]}"
        status, raw = self.table(
            a,
            "user_profiles",
            f"id=eq.{uid_a}",
            "PATCH",
            {"avatar_url": profile_ref},
        )
        rows = parse_json(status, raw, "persist stable avatar reference")
        self.check("profile stores stable avatar reference",
                   isinstance(rows, list) and len(rows) == 1 and
                   rows[0].get("avatar_url") == profile_ref)
        return objects

    def function_checks(self, a: dict[str, str], image_base64: str) -> None:
        for name in ("analyze-clothing", "delete-account", "style-coach"):
            status, _ = request(
                "POST",
                f"{self.url}/functions/v1/{name}",
                {"apikey": self.anon, "Content-Type": "application/json"},
                {},
            )
            self.check(f"unauthenticated {name} request is rejected",
                       status in (401, 403))
            status, _ = request(
                "POST",
                f"{self.url}/functions/v1/{name}",
                {"apikey": self.anon, "Authorization": "Bearer invalid-token",
                 "Content-Type": "application/json"},
                {},
            )
            self.check(f"invalid JWT for {name} is rejected",
                       status in (401, 403))

        requests = {
            "analyze-clothing": {"imageBase64": image_base64,
                                 "requestId": str(uuid.uuid4())},
            "ai-suggestions": {"imageBase64": image_base64,
                               "requestId": str(uuid.uuid4()), "language": "EN"},
            "today-suggestion": {"requestId": str(uuid.uuid4())},
            "style-coach": {"requestId": str(uuid.uuid4()), "mode": "active"},
            "generate-ai-insights": {"requestId": str(uuid.uuid4()),
                                     "timeRange": "month"},
        }
        for name, body in requests.items():
            status, raw = request(
                "POST",
                f"{self.url}/functions/v1/{name}",
                self.headers(a["token"]),
                body,
            )
            data = {}
            try:
                data = json.loads(raw)
            except (UnicodeDecodeError, json.JSONDecodeError):
                pass
            self.check(f"{name} reports provider unavailable without inference",
                       status == 503 and isinstance(data, dict) and
                       data.get("code") == "AI_UNAVAILABLE")

        status, raw = request(
            "POST",
            f"{self.url}/functions/v1/verify-purchase",
            self.headers(a["token"]),
            {},
        )
        self.check("purchase verification fails closed without provider config",
                   status == 503)

        status, raw = request(
            "POST",
            f"{self.url}/functions/v1/check-and-request-suggestion",
            self.headers(a["token"]),
            {},
        )
        result = parse_json(status, raw, "authenticated allowance preflight")
        self.check("authenticated allowance endpoint reports free quota",
                   isinstance(result, dict) and result.get("allowed") is True and
                   result.get("allowance", {}).get("tier") == "free")
        status, raw = self.rest(
            a, "POST", "rest/v1/rpc/get_ai_allowance", {}
        )
        allowance = parse_json(status, raw, "allowance after unavailable AI")
        self.check("unavailable AI does not consume allowance",
                   isinstance(allowance, dict) and allowance.get("month_used") == 0)

    def exhausted_preflight_check(self, a: dict[str, str]) -> None:
        status, raw = request(
            "POST",
            f"{self.url}/functions/v1/check-and-request-suggestion",
            self.headers(a["token"]),
            {},
        )
        result = parse_json(status, raw, "exhausted allowance preflight")
        allowance = result.get("allowance") if isinstance(result, dict) else None
        self.check("allowance endpoint reports exhausted burst",
                   isinstance(result, dict) and result.get("allowed") is False
                   and isinstance(allowance, dict)
                   and allowance.get("burst_remaining") == 0)

    def deletion_checks(self, a: dict[str, str], b: dict[str, str],
                        objects: list[tuple[str, str]]) -> None:
        uid_a = a["id"]
        status, raw = request(
            "POST",
            f"{self.url}/functions/v1/delete-account",
            self.headers(a["token"]),
            {},
        )
        self.check("account deletion endpoint accepts synthetic user A",
                   200 <= status < 300)
        self.deleted_users.add(uid_a)

        status, raw = self.table(
            None, "user_profiles", f"id=eq.{uid_a}&select=id", admin=True
        )
        rows = parse_json(status, raw, "verify deleted profile")
        self.check("account deletion removes profile",
                   isinstance(rows, list) and not rows)
        for bucket, _path in objects:
            status, raw = self.rest(
                None,
                "POST",
                f"storage/v1/object/list/{bucket}",
                {"prefix": uid_a, "limit": 100},
                admin=True,
            )
            entries = parse_json(status, raw, f"verify deleted {bucket} objects")
            self.check(f"account deletion removes {bucket} objects",
                       isinstance(entries, list) and not entries)
        status, _ = request(
            "GET",
            f"{self.url}/auth/v1/admin/users/{uid_a}",
            self.headers(admin=True),
        )
        self.check("account deletion removes Auth identity",
                   status == 404)
        status, raw = self.table(
            b, "user_profiles", f"id=eq.{b['id']}&select=id"
        )
        rows = parse_json(status, raw, "user B profile survives A deletion")
        self.check("deleting user A does not remove user B",
                   isinstance(rows, list) and len(rows) == 1)

    def cleanup(self) -> None:
        for user in reversed(self.users):
            uid = user["id"]
            for bucket, path in self.uploaded_objects:
                if path.split("/", 1)[0] != uid:
                    continue
                self.rest(
                    None,
                    "DELETE",
                    f"storage/v1/object/{bucket}",
                    {"prefixes": [path]},
                    admin=True,
                )
            self.auth_admin(uid)


def read_config(path: pathlib.Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    mode = stat.S_IMODE(resolved.stat().st_mode)
    if mode & 0o077:
        raise CheckFailure("config permissions must be 0600")
    repository = pathlib.Path(__file__).resolve().parents[1]
    if os.path.commonpath((str(resolved), str(repository))) == str(repository):
        raise CheckFailure("keep staging credentials outside the checkout")
    config = json.loads(resolved.read_text())
    expected = {"SUPABASE_URL", "SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY"}
    if not isinstance(config, dict) or set(config) != expected:
        raise CheckFailure("config must contain only the three required staging fields")
    if config.get("SUPABASE_URL", "").rstrip("/") != EXPECTED_URL:
        raise CheckFailure("refusing a non-staging project URL")
    if not config["SUPABASE_ANON_KEY"] or not config["SUPABASE_SERVICE_ROLE_KEY"]:
        raise CheckFailure("staging API keys are required")
    return config


REALTIME_NODE = r"""
const chunks=[]; for await (const chunk of process.stdin) chunks.push(chunk);
const input=JSON.parse(Buffer.concat(chunks).toString());
const base=new URL(input.url);
const wsUrl=`wss://${base.host}/realtime/v1/websocket?apikey=${encodeURIComponent(input.anon)}&vsn=1.0.0`;
const sockets=[]; let closed=false;
function finish(result){if(closed)return;closed=true;clearTimeout(timeout);for(const s of sockets)try{s.close()}catch{};process.stdout.write(result);if(!result.startsWith('PASS'))process.exitCode=1;}
const timeout=setTimeout(()=>finish('FAIL:timeout'),10000);
function connect(label,user){return new Promise((resolve,reject)=>{
  const ws=new WebSocket(wsUrl);sockets.push(ws);const state={ws,events:0,joined:false};
  ws.onerror=()=>reject(new Error('socket'));
  ws.onopen=()=>ws.send(JSON.stringify({topic:`realtime:everywear-smoke-${label}`,event:'phx_join',payload:{config:{broadcast:{ack:false,self:false},presence:{key:''},postgres_changes:[{event:'INSERT',schema:'public',table:'wardrobe_items',filter:`user_id=eq.${user.id}`}],private:false},access_token:user.token},ref:'1'}));
  ws.onmessage=event=>{let msg;try{msg=JSON.parse(event.data)}catch{return}
    if(msg.event==='phx_reply'&&String(msg.ref)==='1'){if(msg.payload?.status==='ok'){state.joined=true;resolve(state)}else reject(new Error('join'))}
    if(msg.event==='postgres_changes'&&msg.payload?.data?.record?.user_id===user.id)state.events++;
  };
})}
(async()=>{try{
  const [a,b]=await Promise.all([connect('a',input.a),connect('b',input.b)]);
  const response=await fetch(`${input.url}/rest/v1/wardrobe_items`,{method:'POST',headers:{apikey:input.anon,Authorization:`Bearer ${input.a.token}`,'Content-Type':'application/json',Prefer:'return=minimal'},body:JSON.stringify({user_id:input.a.id,name:'Realtime synthetic fixture',category:'Tops'})});
  if(!response.ok){finish('FAIL:insert');return;}
  await new Promise(r=>setTimeout(r,1400));
  if(a.events!==1){finish(`FAIL:user-a-events-${a.events}`);return;}
  if(b.events!==0){finish(`FAIL:user-b-events-${b.events}`);return;}
  finish('PASS');
}catch(error){finish(`FAIL:${error?.message==='join'?'join':error?.message==='socket'?'socket':'protocol'}`)}})();
"""


def realtime_check(smoke: StagingSmoke, a: dict[str, str], b: dict[str, str]) -> None:
    payload = {
        "url": smoke.url,
        "anon": smoke.anon,
        "a": {"id": a["id"], "token": a["token"]},
        "b": {"id": b["id"], "token": b["token"]},
    }
    try:
        result = subprocess.run(
            ["node", "-e", REALTIME_NODE],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        smoke.check("Realtime two-user subscription", False)
        return
    detail = result.stdout.strip() if result.returncode == 0 else "runner-error"
    smoke.check(
        f"Realtime sends A's change only to user A ({detail})",
        result.returncode == 0 and detail == "PASS",
    )


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print("usage: staging_free_beta_smoke.py PRIVATE_CONFIG.json [all|realtime|storage|security]",
              file=sys.stderr)
        return 2
    mode = sys.argv[2] if len(sys.argv) == 3 else "all"
    if mode not in {"all", "realtime", "storage", "security"}:
        print("unsupported staging smoke mode", file=sys.stderr)
        return 2
    smoke: StagingSmoke | None = None
    try:
        smoke = StagingSmoke(read_config(pathlib.Path(sys.argv[1])))
        try:
            a = smoke.create_user("a")
            b = smoke.create_user("b")
            if mode == "realtime":
                realtime_check(smoke, a, b)
            elif mode == "security":
                smoke.profile_checks(a, b)
                smoke.wardrobe_checks(a, b)
                image = subprocess.run(
                    ["convert", "-size", "1x1", "xc:white", "jpg:-"],
                    capture_output=True,
                    timeout=10,
                    check=True,
                ).stdout
                smoke.function_checks(a, base64.b64encode(image).decode("ascii"))
                smoke.quota_checks(a, b)
                smoke.exhausted_preflight_check(a)
            elif mode == "storage":
                objects = smoke.storage_checks(a, b)
                smoke.deletion_checks(a, b, objects)
                status, _ = request(
                    "POST",
                    f"{smoke.url}/functions/v1/delete-account",
                    smoke.headers(b["token"]),
                    {},
                )
                smoke.check("account deletion endpoint accepts synthetic user B",
                            200 <= status < 300)
                smoke.deleted_users.add(b["id"])
            else:
                smoke.profile_checks(a, b)
                smoke.wardrobe_checks(a, b)
                image = subprocess.run(
                    ["convert", "-size", "1x1", "xc:white", "jpg:-"],
                    capture_output=True,
                    timeout=10,
                    check=True,
                ).stdout
                image_base64 = base64.b64encode(image).decode("ascii")
                smoke.function_checks(a, image_base64)
                smoke.quota_checks(a, b)
                smoke.exhausted_preflight_check(a)
                realtime_check(smoke, a, b)
                objects = smoke.storage_checks(a, b)
                smoke.deletion_checks(a, b, objects)
                status, _ = request(
                    "POST",
                    f"{smoke.url}/functions/v1/delete-account",
                    smoke.headers(b["token"]),
                    {},
                )
                smoke.check("account deletion endpoint accepts synthetic user B",
                            200 <= status < 300)
                smoke.deleted_users.add(b["id"])
        finally:
            smoke.cleanup()
    except CheckFailure as error:
        if smoke is not None:
            for name, passed in smoke.results:
                print(f"{'PASS' if passed else 'FAIL'} {name}")
        if smoke is None or all(passed for _, passed in smoke.results):
            print(f"FAIL {str(error).split(':', 1)[0]}")
        return 1
    except Exception as error:
        if smoke is not None:
            for name, passed in smoke.results:
                print(f"{'PASS' if passed else 'FAIL'} {name}")
        print(f"FAIL smoke runner error: {type(error).__name__}")
        return 1
    if smoke is None:
        return 1
    for name, passed in smoke.results:
        print(f"{'PASS' if passed else 'FAIL'} {name}")
    print(f"RESULT {sum(p for _, p in smoke.results)}/{len(smoke.results)} passed")
    return 0 if all(passed for _, passed in smoke.results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
