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
  const authelia = page.getByRole('button', { name: 'Continue with Authelia' })
  await getStarted.or(authelia).first().waitFor({ state: 'visible', timeout: 30_000 })
  if (await getStarted.isVisible().catch(() => false)) {
    await getStarted.click()
    await getStarted.waitFor({ state: 'hidden', timeout: 10_000 })
  }
  await authelia.click()
  await loginOidc(page, creds)
  const consent = page.locator('#openid-consent-accept')
  if (await consent.isVisible({ timeout: 10_000 }).catch(() => false)) {
    await consent.click()
  }
  await dismissSplashes(page)
}

export async function dismissSplashes(page: Page): Promise<void> {
  const whatsNew = page.getByRole('button', { name: /Okay, Let's Go!?/i })
  if (await whatsNew.isVisible({ timeout: 15_000 }).catch(() => false)) {
    await whatsNew.click()
  }
  const okay = page.getByRole('button', { name: /^Okay/ })
  if (await okay.isVisible({ timeout: 5_000 }).catch(() => false)) {
    await okay.click()
  }
  const updateToast = page.locator('button[aria-label="Close"]').first()
  if (await updateToast.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await updateToast.click().catch(() => {})
  }
}
