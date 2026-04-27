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
  const getStarted = page.getByRole('button', { name: 'Get started' })
  if (await getStarted.isVisible({ timeout: 5_000 }).catch(() => false)) {
    await getStarted.click()
    await getStarted.waitFor({ state: 'hidden', timeout: 10_000 })
  }
  await page.getByRole('button', { name: 'Continue with Authelia' }).click()
  await loginOidc(page, creds)
  const consent = page.locator('#openid-consent-accept')
  if (await consent.isVisible({ timeout: 10_000 }).catch(() => false)) {
    await consent.click()
  }
  const okay = page.getByRole('button', { name: /Okay/ })
  if (await okay.isVisible({ timeout: 10_000 }).catch(() => false)) {
    await okay.click()
  }
}
