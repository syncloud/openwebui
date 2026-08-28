local name = 'openwebui';
local openwebui = '0.11.1';
local ollama = '0.14.2';
local nginx = '1.29.3-alpine3.22';
local debian = 'bookworm-slim';
local platform = '26.04.10';
local playwright = 'v1.59.1-jammy';
local store_publisher = 'stable-346';
local python = '3.12-slim-bookworm';
local go = '1.25';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];

local platform_image(distro, arch) =
  'syncloud/platform-' + distro + '-' + arch + ':' + platform;

local build(arch, test_ui) = [{
  kind: 'pipeline',
  type: 'docker',
  name: arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'version',
      image: 'debian:' + debian,
      commands: ['echo $DRONE_BUILD_NUMBER > version'],
    },
    {
      name: 'ollama',
      image: 'ollama/ollama:' + ollama,
      commands: ['./ollama/build.sh'],
    },
  ] + [
    {
      name: 'ollama test ' + distro,
      image: platform_image(distro, arch),
      commands: ['./ollama/test.sh'],
    }
    for distro in distros
  ] + [
    {
      name: 'openwebui',
      image: 'ghcr.io/open-webui/open-webui:' + openwebui,
      commands: ['./openwebui/build.sh'],
    },
  ] + [
    {
      name: 'openwebui test ' + distro,
      image: platform_image(distro, arch),
      commands: ['./openwebui/test.sh'],
    }
    for distro in distros
  ] + [
    {
      name: 'cli',
      image: 'golang:' + go,
      commands: ['./cli/build.sh'],
    },
    {
      name: 'package',
      image: 'debian:' + debian,
      commands: [
        'VERSION=$(cat version)',
        './package.sh ' + name + ' $VERSION ',
      ],
    },
  ] + [
    {
      name: 'test ' + distro,
      image: 'python:' + python,
      commands: [
        'cd test',
        './deps.sh',
        'py.test -x -s test.py --distro=' + distro + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
      ],
    }
    for distro in distros
  ] + (if test_ui then [
         {
           name: 'test-ui-desktop',
           image: 'mcr.microsoft.com/playwright:' + playwright,
           environment: { DEVICE_USER: 'user', DEVICE_PASSWORD: 'Password1' },
           commands: [
             './ci/ui.sh desktop ' + name + ' ' + distro_default + ' $DRONE_BUILD_NUMBER',
           ],
         },
         {
           name: 'test-upgrade',
           image: 'python:' + python,
           commands: [
             'cd test',
             './deps.sh',
             'py.test -x -s upgrade.py --distro=' + distro_default + ' --ver=$DRONE_BUILD_NUMBER --app=' + name,
           ],
           privileged: true,
         },
       ] else []) + [
    {
      name: 'publish',
      image: 'syncloud/store-publisher:' + store_publisher,
      environment: {
        SYNCLOUD_TOKEN: { from_secret: 'SYNCLOUD_TOKEN' },
      },
      command: ['snap', '-c', '${DRONE_BRANCH}'],
      when: {
        branch: ['stable'],
        event: ['push'],
      },
    },
    {
      name: 'artifact',
      image: 'appleboy/drone-scp:1.6.4',
      settings: {
        host: { from_secret: 'artifact_host' },
        username: 'artifact',
        key: { from_secret: 'artifact_key' },
        timeout: '2m',
        command_timeout: '2m',
        target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
        source: 'artifact/*',
        strip_components: 1,
      },
      when: {
        status: ['failure', 'success'],
        event: ['push'],
      },
    },
  ],
  trigger: {
    event: ['push'],
  },
  services: [
    {
      name: name + '.' + distro + '.com',
      image: platform_image(distro, arch),
      privileged: true,
      entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
      volumes: [
        { name: 'dbus', path: '/var/run/dbus' },
        { name: 'dev', path: '/dev' },
      ],
    }
    for distro in distros
  ],
  volumes: [
    { name: 'dbus', host: { path: '/var/run/dbus' } },
    { name: 'dev', host: { path: '/dev' } },
  ],
}];

build('amd64', true) +
build('arm64', false)
