import type { Page } from '@playwright/test'

export type SyncloudCreds = {
  user: string
  password: string
}

export function credsFromEnv(): SyncloudCreds {
  const user = process.env.DEVICE_USER
  const password = process.env.DEVICE_PASSWORD
  if (!user || !password) {
    throw new Error('DEVICE_USER and DEVICE_PASSWORD must be set')
  }
  return { user, password }
}

export async function openApp(page: Page, path = ''): Promise<void> {
  await page.goto(path, { waitUntil: 'domcontentloaded' })
}

export async function loginOidc(page: Page, creds: SyncloudCreds): Promise<void> {
  await page.locator('#username-textfield').fill(creds.user)
  await page.locator('#password-textfield').fill(creds.password)
  await page.locator('#sign-in-button').click()
}

export async function acceptConsent(page: Page): Promise<void> {
  await page.locator('#openid-consent-accept').click()
}

export async function loginToOpenWebUI(page: Page, creds: SyncloudCreds): Promise<void> {
  await openApp(page)
  const getStarted = page.locator('xpath=//div[.="Get started"]/../button')
  if (await getStarted.isVisible({ timeout: 5_000 }).catch(() => false)) {
    await getStarted.click()
  }
  await page.locator('xpath=//span[.="Continue with Authelia"]').click()
  await page.waitForURL(/^https:\/\/auth\./, { timeout: 30_000 })
  await loginOidc(page, creds)
  await page.waitForURL((url) => url.pathname.includes('/consent/') || !url.pathname.startsWith('/auth/'), {
    timeout: 30_000,
  })
  if (page.url().includes('/consent/')) {
    await acceptConsent(page)
  }
  await page.waitForURL((url) => !url.pathname.startsWith('/auth/') && !url.pathname.includes('/consent/'), {
    timeout: 30_000,
  })
  const okay = page.locator('xpath=//button[contains(.,"Okay")]')
  if (await okay.isVisible({ timeout: 10_000 }).catch(() => false)) {
    await okay.click()
  }
}
