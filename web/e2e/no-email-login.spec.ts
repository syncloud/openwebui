import { test, expect } from '@playwright/test'
import { loginToOpenWebUI } from './helpers/syncloud'

test('user with no email logs in via OAUTH email fallback', async ({ page }) => {
  const user = process.env.NO_EMAIL_USER
  const password = process.env.NO_EMAIL_PASSWORD
  if (!user || !password) {
    throw new Error('NO_EMAIL_USER and NO_EMAIL_PASSWORD must be set')
  }
  await loginToOpenWebUI(page, { user, password })
  await expect(page.locator('xpath=//div[contains(.,"Hello,")]')).toBeVisible({ timeout: 30_000 })
})
