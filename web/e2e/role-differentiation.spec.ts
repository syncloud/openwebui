import { test, expect, type Browser, type Page } from '@playwright/test'
import { credsFromEnv, loginToOpenWebUI } from './helpers/syncloud'

const LAM_USER_LOGIN = process.env.LAM_USER_LOGIN ?? 'lamuser'
const LAM_USER_PASSWORD = process.env.LAM_USER_PASSWORD ?? 'Repr0duce!Bug-2026-Strong'

async function freshLogin(browser: Browser, user: string, password: string, tag: string): Promise<Page> {
  const ctx = await browser.newContext({ ignoreHTTPSErrors: true })
  const page = await ctx.newPage()
  await loginToOpenWebUI(page, { user, password })
  await page.locator('xpath=//div[contains(.,"Hello,")]').first().waitFor({ state: 'visible', timeout: 45_000 })
  await page.screenshot({ path: `test-results/role-${tag}-home.png`, fullPage: true })
  return page
}

test('admin reaches Admin Panel, regular user is bounced from /admin/users', async ({ browser }) => {
  test.setTimeout(180_000)
  const admin = credsFromEnv()

  const adminPage = await freshLogin(browser, admin.user, admin.password, 'admin')
  await adminPage.goto('/admin/users')
  await adminPage.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {})
  await adminPage.screenshot({ path: 'test-results/role-admin-admin-users.png', fullPage: true })
  expect(await adminPage.title()).toMatch(/Admin Panel/)
  expect(adminPage.url()).toMatch(/\/admin\/users/)

  const userPage = await freshLogin(browser, LAM_USER_LOGIN, LAM_USER_PASSWORD, 'regular')
  await userPage.goto('/admin/users')
  await userPage.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {})
  await userPage.screenshot({ path: 'test-results/role-regular-admin-users.png', fullPage: true })
  expect(await userPage.title()).not.toMatch(/Admin Panel/)
})
