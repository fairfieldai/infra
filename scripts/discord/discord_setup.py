"""Configure the parts of the fairfieldct.ai Discord server that Terraform can't yet.

Creates or updates the AutoMod rules, registers the slash commands, and registers the Linked Roles
metadata. Roles, channels, permissions, server settings, the rules post, the invite, and the
webhooks are managed by Terraform in environments/discord.

The bot's token is read from SSM. With --dry-run, nothing changes; each create or update is
printed instead.
"""

import argparse
import json
import os
import subprocess
import time
import urllib.error
import urllib.request
from typing import Any, Protocol

GUILD_ID = "1557456560488448190"
APPLICATION_ID = "1557457463534686319"
TOKEN_PARAMETER = "/fairfieldct-ai/discord-bot-token"
AWS_PROFILE = "fairfieldct-ai-admin"
AWS_REGION = "us-east-1"
MAX_ATTEMPTS = 6
TOO_MANY_REQUESTS = 429

type Json = Any


class Api(Protocol):
    """The Discord API calls setup needs."""

    dry_run: bool

    def get(self, path: str) -> Json:
        """Read a resource."""
        ...

    def write(self, method: str, path: str, body: Json, *, describe: str) -> Json:
        """Create or change a resource, or only describe the change in a dry run."""
        ...


class Discord:
    """Discord REST API client authenticated as the bot."""

    def __init__(self, token: str, *, dry_run: bool) -> None:
        """Create a client for the bot token."""
        self.token = token
        self.dry_run = dry_run

    def get(self, path: str) -> Json:
        """Read a resource."""
        return self._request("GET", path)

    def write(self, method: str, path: str, body: Json, *, describe: str) -> Json:
        """Make a change, or only print it in a dry run."""
        print(("would " if self.dry_run else "") + describe)
        if self.dry_run:
            return None
        return self._request(method, path, body)

    def _request(self, method: str, path: str, body: Json = None) -> Json:
        data = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(
            f"https://discord.com/api/v10{path}",
            data=data,
            method=method,
            headers={
                "Authorization": f"Bot {self.token}",
                "Content-Type": "application/json",
                "User-Agent": "DiscordBot (https://www.fairfieldct.ai, 1.0)",
            },
        )
        for _ in range(MAX_ATTEMPTS):
            try:
                with urllib.request.urlopen(request) as response:
                    raw = response.read()
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as error:
                detail = error.read()
                if error.code == TOO_MANY_REQUESTS:
                    time.sleep(float(json.loads(detail).get("retry_after", 1)) + 0.25)
                    continue
                message = f"{method} {path} -> {error.code}: {detail.decode()[:500]}"
                raise SystemExit(message) from error
        raise SystemExit(f"{method} {path}: still rate limited after {MAX_ATTEMPTS} attempts")


def ensure_automod(api: Api) -> None:
    """Add spam and keyword filters alongside Discord's default mention-spam rule."""
    existing = {r["trigger_type"]: r for r in api.get(f"/guilds/{GUILD_ID}/auto-moderation/rules")}
    block = [{"type": 1, "metadata": {"custom_message": "This message was blocked by AutoMod."}}]
    wanted = [
        (3, "Block spam content", {}),
        (4, "Block sexual content and slurs", {"trigger_metadata": {"presets": [2, 3]}}),
    ]
    for trigger, name, extra in wanted:
        body = {"name": name, "event_type": 1, "actions": block, "enabled": True, **extra}
        if trigger in existing:
            path = f"/guilds/{GUILD_ID}/auto-moderation/rules/{existing[trigger]['id']}"
            api.write("PATCH", path, body, describe=f"update AutoMod rule {name}")
        else:
            path = f"/guilds/{GUILD_ID}/auto-moderation/rules"
            body["trigger_type"] = trigger
            api.write("POST", path, body, describe=f"create AutoMod rule {name}")


COMMANDS = [
    {"name": "ping", "description": "Check that the fairfieldct.ai bot is listening", "type": 1},
    {"name": "meetup", "description": "Show the next fairfieldct.ai meetup", "type": 1},
]


# Linked Roles metadata the site API sets on each member's role connection
# (fairfieldai/site, crates/api/src/discord_link.rs). Type 7 is BOOLEAN_EQUAL.
ROLE_CONNECTION_METADATA = [
    {
        "type": 7,
        "key": "member",
        "name": "fairfieldct.ai member",
        "description": "Has a fairfieldct.ai account",
    },
]


def register_role_connection_metadata(api: Api) -> None:
    """Tell Discord which Linked Roles fields the application sets."""
    path = f"/applications/{APPLICATION_ID}/role-connections/metadata"
    describe = "register Linked Roles metadata (member)"
    api.write("PUT", path, ROLE_CONNECTION_METADATA, describe=describe)


def register_commands(api: Api) -> None:
    """Register the slash commands the Discord Lambda in fairfieldai/site handles."""
    names = ", ".join(f"/{command['name']}" for command in COMMANDS)
    path = f"/applications/{APPLICATION_ID}/commands"
    api.write("PUT", path, COMMANDS, describe=f"register {names}")


def setup(api: Api) -> None:
    """Bring AutoMod, the slash commands, and the Linked Roles metadata up to date."""
    ensure_automod(api)
    register_commands(api)
    register_role_connection_metadata(api)


def ssm_parameter(name: str) -> str:
    """Read and decrypt an SSM parameter with the AWS CLI."""
    command = [
        "aws", "ssm", "get-parameter", "--profile", AWS_PROFILE, "--region", AWS_REGION,
        "--name", name, "--with-decryption", "--query", "Parameter.Value", "--output", "text",
    ]  # fmt: skip
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout.strip()


def main() -> None:
    """Parse arguments and run setup."""
    parser = argparse.ArgumentParser(
        description="Configure Discord AutoMod, slash commands, and Linked Roles metadata."
    )
    parser.add_argument("--dry-run", action="store_true", help="print changes without making them")
    args = parser.parse_args()
    token = os.environ.get("DISCORD_TOKEN") or ssm_parameter(TOKEN_PARAMETER)
    setup(Discord(token, dry_run=args.dry_run))


if __name__ == "__main__":
    main()
