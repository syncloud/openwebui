import { appendFileSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { ssh } from './helpers/ssh'

const APP = process.env.PLAYWRIGHT_APP ?? 'openwebui'
const DOMAIN = process.env.PLAYWRIGHT_DOMAIN ?? 'bookworm.com'

async function probe(url: string, timeoutMs: number): Promise<number> {
  const deadline = Date.now() + timeoutMs
  while (Date.now() < deadline) {
    try {
      const code = execFileSync('curl', ['-sk', '-o', '/dev/null', '-w', '%{http_code}', url], {
        encoding: 'utf8',
        timeout: 15_000,
      }).trim()
      if (code === '200') return 200
    } catch {}
    await new Promise(r => setTimeout(r, 3_000))
  }
  return 0
}

export default async function () {
  const appHost = `${APP}.${DOMAIN}`
  const platformIp = execFileSync('getent', ['hosts', appHost], { encoding: 'utf8' }).split(/\s+/)[0]
  if (!platformIp) throw new Error(`cannot resolve ${appHost}`)
  for (const host of ['auth', 'users']) {
    appendFileSync('/etc/hosts', `${platformIp} ${host}.${DOMAIN}\n`)
  }

  ssh('snap install users 2>&1 || snap refresh users 2>&1 || true; snap list users', { throw: false })

  for (const host of [APP, 'users', 'auth']) {
    const url = `https://${host}.${DOMAIN}/`
    const code = await probe(url, 180_000)
    if (code !== 200) {
      throw new Error(`${url} not ready: HTTP ${code}`)
    }
    console.log(`${url} -> 200`)
  }
}
