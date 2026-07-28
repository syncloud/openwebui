import { appendFileSync } from 'node:fs'
import { execFileSync } from 'node:child_process'

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
  appendFileSync('/etc/hosts', `${platformIp} auth.${DOMAIN}\n`)

  for (const host of [APP, 'auth']) {
    const url = `https://${host}.${DOMAIN}/`
    const code = await probe(url, 180_000)
    if (code !== 200) {
      throw new Error(`${url} not ready: HTTP ${code}`)
    }
    console.log(`${url} -> 200`)
  }
}
