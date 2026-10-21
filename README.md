# gitcrew-sandbox

The container image for one Hermes or OpenClaw review.

GitCrew's app does not contain these loops. This image clones the commits in `loops.lock.json`, runs one loop against a checkout mounted at `/workspace`, and prints an AgentResult as JSON. It has no GitHub token and it does not push.

Memory is optional. When the worker mounts it at `/memory`, Hermes uses that directory as `HERMES_HOME` and OpenClaw uses it as `--state-dir`. The image never deletes that mount.

Build on the worker machine:

```bash
docker build -t gitcrew-sandbox:local .
```

The OpenClaw build inside the image is large. Run it once on the machine that will host the worker.
