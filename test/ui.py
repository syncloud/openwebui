import time
from os.path import dirname, join
from subprocess import check_output

import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from syncloudlib.integration.hosts import add_host_alias

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode, driver, selenium):
    def teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.run_ssh('ls -lah /data/openwebui/ollama > {0}/data.ollama.ls.log'.format(TMP_DIR), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)
        #selenium.log()

    request.addfinalizer(teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    selenium.open_app()
    selenium.find_by(By.XPATH, "//div[.='Get started']/../button").click()
    selenium.find_by(By.XPATH, "//span[.='Continue with Authelia']").click()
    selenium.find_by(By.ID, "username-textfield").send_keys(device_user)
    password = selenium.find_by(By.ID, "password-textfield")
    password.send_keys(device_password)
    selenium.screenshot('login')
    #password.send_keys(Keys.RETURN)
    selenium.find_by(By.ID, "sign-in-button").click()
    selenium.find_by(By.ID, "accept-button").click()
    selenium.find_by(By.XPATH, "//button[contains(.,'Okay')]").click()
    selenium.find_by(By.XPATH, "//div[contains(.,'Hello, user')]")
    selenium.screenshot('main')


def test_upload_epub(selenium, device_user, device_password):
    file_input = selenium.find_by(By.XPATH, "//input[@type='file']")
    file_input.send_keys(join(DIR, 'data', 'test.epub'))
    # Wait for spinner to disappear (upload complete)
    selenium.invisible_by(By.CSS_SELECTOR, ".spinner_ajPY")
    selenium.screenshot('epub-upload')
    # Verify no error toast on page
    page_source = selenium.driver.page_source
    assert 'data-type="error"' not in page_source, \
        'Error toast detected on page after epub upload'
