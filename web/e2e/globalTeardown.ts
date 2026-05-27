import { ssh } from './helpers/ssh'
import { mkdirSync, writeFileSync, readdirSync, copyFileSync, statSync, existsSync, rmSync } from 'node:fs'
import { join, basename } from 'node:path'

const APP = process.env.PLAYWRIGHT_APP ?? 'openwebui'
const ART = process.env.PLAYWRIGHT_ARTIFACT_DIR ?? '/drone/src/artifact/e2e'

function copyRecursive(src: string, dst: string) {
  mkdirSync(dst, { recursive: true })
  for (const name of readdirSync(src)) {
    const s = join(src, name)
    const d = join(dst, name)
    if (statSync(s).isDirectory()) copyRecursive(s, d)
    else copyFileSync(s, d)
  }
}

export default async function () {
  const project = 'desktop'
  const out = join(ART, project)
  mkdirSync(out, { recursive: true })

  try {
    const log = ssh(`journalctl --since "30 min ago" --no-pager`, { throw: false })
    writeFileSync(join(out, 'journalctl.log'), log)
  } catch {}

  const testResults = 'test-results'
  if (existsSync(testResults)) {
    for (const entry of readdirSync(testResults)) {
      const full = join(testResults, entry)
      const st = statSync(full)
      if (st.isFile() && entry.endsWith('.png')) {
        copyFileSync(full, join(out, entry))
      } else if (st.isDirectory()) {
        for (const f of readdirSync(full)) {
          if (f.endsWith('.png')) copyFileSync(join(full, f), join(out, `${entry}-${f}`))
        }
        const errOut = join(out, 'errors', entry)
        let needsErr = false
        mkdirSync(errOut, { recursive: true })
        for (const f of ['error-context.md', 'trace.zip']) {
          const src = join(full, f)
          if (existsSync(src)) {
            copyFileSync(src, join(errOut, f))
            needsErr = true
          }
        }
        if (!needsErr) rmSync(errOut, { recursive: true, force: true })
      }
    }
  }
}
