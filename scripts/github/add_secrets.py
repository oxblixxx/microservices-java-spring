#!/usr/bin/env python3
import os, base64, requests
from dotenv import load_dotenv, dotenv_values
from nacl import public

load_dotenv()
TOKEN, OWNER, REPO, ENV = (
    os.getenv(k) for k in ("GITHUB_TOKEN", "OWNER", "REPO", "ENVIRONMENT")
)
if not all((TOKEN, OWNER, REPO, ENV)):
    raise SystemExit("Missing GitHub configuration in .env")

API = f"https://api.github.com/repos/{OWNER}/{REPO}/environments/{ENV}"
S = requests.Session()
S.headers.update({
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
})


def api(method, url, **kwargs):
    r = S.request(method, url, timeout=30, **kwargs)
    r.raise_for_status()
    return r


def sync():
    entries = dotenv_values(os.getenv("ENV_FILE", ".env.github"), interpolate=False)
    secrets = {k[7:]: v for k, v in entries.items()
               if k.startswith("SECRET_") and v is not None}
    variables = {k[4:]: v for k, v in entries.items()
                 if k.startswith("VAR_") and v is not None}

    api("PUT", API)  # Create environment if missing
    print(f"Environment ready: {ENV}")

    if secrets:
        key = api("GET", f"{API}/secrets/public-key").json()
        box = public.SealedBox(public.PublicKey(base64.b64decode(key["key"])))
        for name, value in secrets.items():
            encrypted = base64.b64encode(box.encrypt(value.encode())).decode()
            api("PUT", f"{API}/secrets/{name}", json={
                "key_id": key["key_id"], "encrypted_value": encrypted
            })
            print(f"Synced secret: {name}")

    existing, url = set(), f"{API}/variables"
    while url:
        r = api("GET", url)
        existing.update(v["name"] for v in r.json().get("variables", []))
        url = r.links.get("next", {}).get("url")

    for name, value in variables.items():
        if name in existing:
            api("PATCH", f"{API}/variables/{name}", json={"value": value})
        else:
            api("POST", f"{API}/variables", json={"name": name, "value": value})
        print(f"Synced variable: {name}")

    print(f"Complete: {len(secrets)} secrets, {len(variables)} variables")


if __name__ == "__main__":
    sync()