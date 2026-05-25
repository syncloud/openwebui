local name = 'openwebui';
local openwebui = '0.9.2';
local ollama = '0.14.2';
local nginx = '1.29.3-alpine3.22';
local debian = 'bookworm-slim';
local platforms = {
  bookworm: '26.04.9',
  buster: '25.02',
};
local playwright = 'v1.59.1-jammy';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';
local python = '3.12-slim-bookworm';
local go = '1.25';
local distro_default = 'bookworm';
local distros = ['bookworm', 'buster'];


local build(arch, test_ui, dind) = [{
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
               commands: [
                 'echo $DRONE_BUILD_NUMBER > version',
               ],
             },
{
      name: 'ollama',
      image: "ollama/ollama:" + ollama,
      commands: [
        './ollama/build.sh',
      ],
    },
    {
      name: 'ollama test',
      image: 'syncloud/platform-' + distro_default + '-' + arch + ':' + platforms[distro_default],
      commands: [
        './ollama/test.sh',
      ],
    },
    {
      name: 'ollama test buster',
      image: 'syncloud/platform-buster-' + arch + ':' + platforms.buster,
      commands: [
        './ollama/test.sh',
      ],
    },
    {
      name: 'openwebui',
      image: "ghcr.io/open-webui/open-webui:" + openwebui,
      commands: [
        './openwebui/build.sh',
      ],
    },
    {
      name: 'openwebui test',
      image: 'syncloud/platform-' + distro_default + '-' + arch + ':' + platforms[distro_default],
      commands: [
        './openwebui/test.sh',
      ],
    },
    {
      name: 'openwebui test buster',
      image: 'syncloud/platform-buster-' + arch + ':' + platforms.buster,
      commands: [
        './openwebui/test.sh',
      ],
    },
    
             {
               name: 'cli',
               image: 'golang:' + go,
               commands: [
                 'cd cli',
                 'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/install ./cmd/install',
                 'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/configure ./cmd/configure',
                 'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/pre-refresh ./cmd/pre-refresh',
                 'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh',
                 'CGO_ENABLED=0 go build -o ../build/snap/bin/cli ./cmd/cli',
               ],
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
        name: 'upload',
        image: 'debian:' + debian,
        environment: {
          AWS_ACCESS_KEY_ID: {
            from_secret: 'AWS_ACCESS_KEY_ID',
          },
          AWS_SECRET_ACCESS_KEY: {
            from_secret: 'AWS_SECRET_ACCESS_KEY',
          },
          SYNCLOUD_TOKEN: {
            from_secret: 'SYNCLOUD_TOKEN',
          },
        },
        commands: [
          'PACKAGE=$(cat package.name)',
          'apt update && apt install -y wget',
          'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
          'chmod +x release',
          './release publish -f $PACKAGE -b $DRONE_BRANCH',
        ],
        when: {
          branch: ['stable', 'master'],
          event: ['push'],
        },
      },
      {
        name: 'promote',
        image: 'debian:' + debian,
        environment: {
          AWS_ACCESS_KEY_ID: {
            from_secret: 'AWS_ACCESS_KEY_ID',
          },
          AWS_SECRET_ACCESS_KEY: {
            from_secret: 'AWS_SECRET_ACCESS_KEY',
          },
          SYNCLOUD_TOKEN: {
            from_secret: 'SYNCLOUD_TOKEN',
          },
        },
        commands: [
          'apt update && apt install -y wget',
          'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
          'chmod +x release',
          './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
        ],
        when: {
          branch: ['stable'],
          event: ['push'],
        },
      },
      {
        name: 'artifact',
        image: 'appleboy/drone-scp:1.6.4',
        settings: {
          host: {
            from_secret: 'artifact_host',
          },
          username: 'artifact',
          key: {
            from_secret: 'artifact_key',
          },
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
      event: [
        'push',
        'pull_request',
      ],
    },
    services: [
      {
        name: 'docker',
        image: 'docker:' + dind,
        privileged: true,
        volumes: [
          {
            name: 'dockersock',
            path: '/var/run',
          },
        ],
      },
    ] + [
      {
        name: name + '.' + distro + '.com',
        image: 'syncloud/platform-' + distro + '-' + arch + ':' + platforms[distro],
        privileged: true,
        entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
        volumes: [
          {
            name: 'dbus',
            path: '/var/run/dbus',
          },
          {
            name: 'dev',
            path: '/dev',
          },
        ],
      }
      for distro in distros
    ],
    volumes: [
      {
        name: 'dbus',
        host: {
          path: '/var/run/dbus',
        },
      },
      {
        name: 'dev',
        host: {
          path: '/dev',
        },
      },
      {
        name: 'dockersock',
        temp: {},
      },
    ],
  },
];

build('amd64', true, '20.10.21-dind') +
build('arm64', false, '20.10.21-dind')
