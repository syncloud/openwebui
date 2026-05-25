import { test, expect, type Browser, type Page } from '@playwright/test'
import { credsFromEnv, loginToOpenWebUI } from './helpers/syncloud'

const APP = process.env.PLAYWRIGHT_APP ?? 'openwebui'
const DOMAIN = process.env.PLAYWRIGHT_DOMAIN ?? 'bookworm.com'
const USERS_URL = `https://users.${DOMAIN}`
const NEW_USER_FIRST = 'lam'
const NEW_USER_LAST = 'user'
const NEW_USER_LOGIN = `${NEW_USER_FIRST}${NEW_USER_LAST}`
const NEW_USER_PASSWORD = 'Repr0duce!Bug-2026-Strong'

async function createLamUser(page: Page, admin: { user: string; password: string }) {
  await page.goto(`${USERS_URL}/log_in/`)
  await page.locator('#user_id').fill(admin.user)
  await page.locator('#confirm').fill(admin.password)
  await page.locator('form button[type=submit], form input[type=submit]').first().click()
  await page.waitForURL(/account_manager|change_password/, { timeout: 15_000 })

  await page.goto(`${USERS_URL}/account_manager/new_user.php`)
  await page.locator('input[name=givenname]').fill(NEW_USER_FIRST)
  await page.locator('input[name=sn]').fill(NEW_USER_LAST)
  await page.locator('input[name=password]').fill(NEW_USER_PASSWORD)
  await page.locator('input[name=password_match]').fill(NEW_USER_PASSWORD)
  await page.evaluate(() => {
    const el = document.getElementById('pass_score') as HTMLInputElement | null
    if (el) el.value = '4'
  })
  await page.locator('button:has-text("Create account")').click()
  const created = page.locator('text=/account was created/i')
  const exists = page.locator('text=/already exists/i')
  await created.or(exists).first().waitFor({ state: 'visible', timeout: 10_000 })
}

async function freshLogin(browser: Browser, creds: { user: string; password: string }, tag: string) {
  const ctx = await browser.newContext({ ignoreHTTPSErrors: true })
  const page = await ctx.newPage()
  await loginToOpenWebUI(page, creds)
  await page.screenshot({ path: `test-results/lam-${tag}.png`, fullPage: true }).catch(() => {})
  return { ctx, page }
}

test('LAM-created user (auto per-user LDAP group) can log in to openwebui', async ({ browser }) => {
  test.setTimeout(180_000)
  const admin = credsFromEnv()

  const setupCtx = await browser.newContext({ ignoreHTTPSErrors: true })
  const setupPage = await setupCtx.newPage()
  await createLamUser(setupPage, admin)
  await setupCtx.close()

  const { ctx: seedCtx } = await freshLogin(browser, admin, 'admin-seed')
  await seedCtx.close()

  const { page: userPage } = await freshLogin(
    browser,
    { user: NEW_USER_LOGIN, password: NEW_USER_PASSWORD },
    'lam-user-attempt',
  )
  await expect(userPage.locator('xpath=//div[contains(.,"Hello,")]').first()).toBeVisible({ timeout: 45_000 })
})
