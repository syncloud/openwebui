import { test, expect } from '@playwright/test'
import { credsFromEnv, loginToOpenWebUI, dismissSplashes } from './helpers/syncloud'
import { createSyncloudUser } from './helpers/syncloud-users'

const LOGIN = 'regularuser'
const PASSWORD = 'Repr0duce!Bug-2026-Strong'

test('regular Syncloud user (no LDAP groups) can log in to openwebui and is NOT an admin', async ({ browser }) => {
  const admin = credsFromEnv()

  createSyncloudUser({ login: LOGIN, password: PASSWORD })

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
