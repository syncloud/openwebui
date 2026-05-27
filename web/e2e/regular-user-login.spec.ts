import { test, expect } from '@playwright/test'
import { credsFromEnv, loginToOpenWebUI, dismissSplashes } from './helpers/syncloud'
import { createSyncloudUser } from './helpers/syncloud-users'

const FIRST = 'regular'
const LAST = 'user'
const LOGIN = `${FIRST}${LAST}`
const PASSWORD = 'Repr0duce!Bug-2026-Strong'

test('regular Syncloud user (auto per-user LDAP group) can log in to openwebui and is NOT an admin', async ({ browser }) => {
  const admin = credsFromEnv()

  const setupCtx = await browser.newContext({ ignoreHTTPSErrors: true })
  await createSyncloudUser(await setupCtx.newPage(), admin, { firstName: FIRST, lastName: LAST, password: PASSWORD })
  await setupCtx.close()

  const adminCtx = await browser.newContext({ ignoreHTTPSErrors: true })
  await loginToOpenWebUI(await adminCtx.newPage(), admin)
  await adminCtx.close()

  const userCtx = await browser.newContext({ ignoreHTTPSErrors: true })
  const page = await userCtx.newPage()
  await loginToOpenWebUI(page, { user: LOGIN, password: PASSWORD })
  await expect(page.locator('xpath=//div[contains(.,"Hello,")]').first()).toBeVisible({ timeout: 45_000 })
  await page.screenshot({ path: 'test-results/regular-user-home.png', fullPage: true })

  await page.goto('/admin/users')
  await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {})
  await dismissSplashes(page)
  await page.screenshot({ path: 'test-results/regular-user-admin-panel-attempt.png', fullPage: true })
  expect(await page.title()).not.toMatch(/Admin Panel/)
})
