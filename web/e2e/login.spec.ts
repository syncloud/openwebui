import { test, expect } from '@playwright/test'
import { credsFromEnv, loginToOpenWebUI } from './helpers/syncloud'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))

test('login as syncloud user and reach main page', async ({ page }) => {
  await loginToOpenWebUI(page, credsFromEnv())
  await expect(page.locator('xpath=//div[contains(.,"Hello,")]')).toBeVisible({ timeout: 30_000 })
})

test('upload epub without errors', async ({ page }) => {
  await loginToOpenWebUI(page, credsFromEnv())
  await expect(page.locator('xpath=//div[contains(.,"Hello,")]')).toBeVisible({ timeout: 30_000 })
  await page.setInputFiles('input[type="file"]', join(__dirname, 'data', 'test.epub'))
  await expect(page.locator('.spinner_ajPY')).toHaveCount(0, { timeout: 60_000 })
  const html = await page.content()
  expect(html).not.toContain('data-type="error"')
  expect(html).not.toContain('data-type="warning"')
})
