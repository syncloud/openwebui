import pytest
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from syncloudlib.integration.installer import local_install
from syncloudlib.http import wait_for_rest
import requests

TMP_DIR = '/tmp/syncloud'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir):
    def module_teardown():
        device.run_ssh('journalctl > {0}/refresh.journalctl.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), artifact_dir)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, device_host, domain, device):
    add_host_alias(app, device_host, domain)
    device.activated()
    device.run_ssh('rm -rf {0}'.format(TMP_DIR), throw=False)
    device.run_ssh('mkdir {0}'.format(TMP_DIR), throw=False)


OLD_REV = '121'


def test_install_old(device, app_domain):
    device.run_ssh('snap remove openwebui', throw=False)
    device.run_ssh(
        'curl -fsSL --retry 10 --retry-delay 10 --retry-all-errors '
        '-o /tmp/openwebui_old.snap '
        'https://apps.syncloud.org/apps/openwebui_{rev}_amd64.snap'.format(rev=OLD_REV),
    )
    device.run_ssh('snap install --dangerous /tmp/openwebui_old.snap')
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


def test_refresh_to_new(device, device_host, device_password, app_archive_path, app_domain):
    local_install(device_host, device_password, app_archive_path)
    wait_for_rest(requests.session(), "https://{0}".format(app_domain), 200, 100)


