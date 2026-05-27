import type { Page } from '@playwright/test'

const DOMAIN = process.env.PLAYWRIGHT_DOMAIN ?? 'bookworm.com'
const USERS_URL = `https://users.${DOMAIN}`

export async function createSyncloudUser(
  page: Page,
  admin: { user: string; password: string },
  newUser: { firstName: string; lastName: string; password: string },
): Promise<void> {
  await page.goto(`${USERS_URL}/log_in/`)
  await page.locator('#user_id').fill(admin.user)
  await page.locator('#confirm').fill(admin.password)
  await page.locator('form button[type=submit], form input[type=submit]').first().click()
  await page.waitForURL(/account_manager|change_password/, { timeout: 15_000 })

  await page.goto(`${USERS_URL}/account_manager/new_user.php`)
  await page.locator('input[name=givenname]').fill(newUser.firstName)
  await page.locator('input[name=sn]').fill(newUser.lastName)
  await page.locator('input[name=password]').fill(newUser.password)
  await page.locator('input[name=password_match]').fill(newUser.password)
  await page.evaluate(() => {
    const el = document.getElementById('pass_score') as HTMLInputElement | null
    if (el) el.value = '4'
  })
  await page.locator('button:has-text("Create account")').click()
  const created = page.locator('text=/account was created/i')
  const exists = page.locator('text=/already exists/i')
  await created.or(exists).first().waitFor({ state: 'visible', timeout: 10_000 })
}
