import { ssh } from './ssh'

export function createSyncloudUser(user: { login: string; password: string }): void {
  ssh(`snap run platform.cli user remove '${user.login}'`, { throw: false })
  ssh(`snap run platform.cli user add '${user.login}' --password='${user.password}'`)
}
