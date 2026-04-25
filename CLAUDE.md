# Debugging CI failures

A build runs one pipeline per arch (amd64, arm64, ...) **in parallel**. One arch can pass while another fails — always inspect every pipeline, not just the first.

List failures grouped by arch (prints `<arch> <step> <status>` for any non-success step):
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/openwebui/builds/{N}" | python3 -c "
import json,sys
b=json.load(sys.stdin)
for stage in b.get('stages',[]):
    arch = stage.get('name')
    for step in stage.get('steps',[]):
        st = step.get('status')
        if st not in ('success','skipped'):
            print(arch, step.get('number'), step.get('name'), '-', st)
"
```

Then get the step log (stage=pipeline number from `stages[].number`, step=step number from above):
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/openwebui/builds/{N}/logs/{stage}/{step}" | python3 -c "
import json,sys; [print(l.get('out',''), end='') for l in json.load(sys.stdin)]
" | tail -80
```

# CI

http://ci.syncloud.org:8080/syncloud/openwebui

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/openwebui/builds?limit=5"
```

Each build contains multiple pipelines (one per arch: amd64, arm64, etc). To check status, look inside `stages` for each pipeline:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/openwebui/builds/{N}" | python3 -c "
import json,sys
b=json.load(sys.stdin)
for s in b.get('stages',[]):
    print(f\"{s['name']}: {s['status']}\")
"
```

## CI Artifacts

Artifacts are served at `http://ci.syncloud.org:8081` (returns JSON directory listings).

Browse the top level for a build (returns distro subdirs + snap file):
```
curl -s "http://ci.syncloud.org:8081/files/openwebui/{build}-{arch}/"
```

Each distro dir contains `app/`, `platform/`, and for upgrade/UI tests also `desktop/`, `refresh.journalctl.log`, `video.mkv`:
```
curl -s "http://ci.syncloud.org:8081/files/openwebui/{build}-{arch}/{distro}/"
curl -s "http://ci.syncloud.org:8081/files/openwebui/{build}-{arch}/{distro}/app/"
curl -s "http://ci.syncloud.org:8081/files/openwebui/{build}-{arch}/{distro}/desktop/"
```

Directory structure:
```
{build}-{arch}/
  {distro}/
    app/
      journalctl.log          # full journal from integration test teardown
      ps.log, netstat.log     # process/network state at teardown
    platform/                 # platform logs
    desktop/                  # UI test artifacts (amd64 only) — Playwright report/test-results
    mobile/                   # UI test artifacts for mobile project
    refresh.journalctl.log    # full journal from upgrade test (pre/post-refresh)
```

Download a file directly:
```
curl -O "http://ci.syncloud.org:8081/files/openwebui/282-amd64/buster/app/journalctl.log"
curl -O "http://ci.syncloud.org:8081/files/openwebui/282-amd64/bookworm/desktop/journalctl.log"
```

# Running Drone builds locally

The `drone` CLI is not on $PATH. It lives at `../drone-cli/drone` (sibling project). Either prefix calls with that path, or add a shell alias.

Generate `.drone.yml` from jsonnet (run from project root):
```
../drone-cli/drone jsonnet --stdout --stream > .drone.yml
```

Run a specific pipeline with selected steps (e.g. amd64 up to `test bookworm`):
```
../drone-cli/drone exec --pipeline amd64 --trusted \
  --include version \
  --include ollama \
  --include "ollama test" \
  --include openwebui \
  --include "openwebui test" \
  --include cli \
  --include package \
  --include "test bookworm" \
  .drone.yml
```

Notes:
- `--trusted` is required for privileged/volume steps
- `--include` selects only listed steps (in pipeline order); omit to run all steps
- `drone jsonnet --stdout --stream` sends stderr to stderr (proto warnings are harmless)
