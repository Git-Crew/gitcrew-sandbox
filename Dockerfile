# One image, two loops. The commits are pinned in loops.lock.json.
# Build this on the worker machine. It clones the loops during the build and does not copy them from the app.

FROM node:24-bookworm

RUN apt-get update \
  && apt-get install -y --no-install-recommends git curl ca-certificates python3 \
  && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /opt
COPY loops.lock.json /opt/loops.lock.json

RUN python3 - <<'PY'
import json, subprocess
lock = json.load(open("/opt/loops.lock.json"))
hermes = lock["hermes"]
subprocess.check_call(["uv", "python", "install", hermes["python"]])
subprocess.check_call(["git", "init", "/opt/hermes"])
subprocess.check_call(["git", "-C", "/opt/hermes", "remote", "add", "origin", hermes["repository"]])
subprocess.check_call(["git", "-C", "/opt/hermes", "fetch", "--depth", "1", "origin", hermes["sha"]])
subprocess.check_call(["git", "-C", "/opt/hermes", "checkout", "FETCH_HEAD"])
subprocess.check_call(["uv", "sync", "--python", hermes["python"], "--project", "/opt/hermes"])
openclaw = lock["openclaw"]
subprocess.check_call(["git", "init", "/opt/openclaw"])
subprocess.check_call(["git", "-C", "/opt/openclaw", "remote", "add", "origin", openclaw["repository"]])
subprocess.check_call(["git", "-C", "/opt/openclaw", "fetch", "--depth", "1", "origin", openclaw["sha"]])
subprocess.check_call(["git", "-C", "/opt/openclaw", "checkout", "FETCH_HEAD"])
PY

RUN corepack enable && corepack prepare pnpm@12.12.1 --activate \
  && cd /opt/openclaw && pnpm install --frozen-lockfile && pnpm build

COPY src /opt/gitcrew-sandbox/src

ENV GITCREW_HERMES_ROOT=/opt/hermes
ENV GITCREW_OPENCLAW_ROOT=/opt/openclaw
ENV GITCREW_PYTHON=/opt/hermes/.venv/bin/python
WORKDIR /workspace
ENTRYPOINT ["node", "/opt/gitcrew-sandbox/src/main.mjs"]
