"""冒烟测试 — 不依赖目标服务器的框架验证"""

import os
import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager


_SYSTEM_CHROMEDRIVER = os.environ.get("CHROMEDRIVER_PATH", "")
_CHROMIUM_BINARY = os.environ.get("CHROMIUM_BINARY", "")


@pytest.fixture(scope="session")
def chromedriver_path():
    """会话级别：获取 ChromeDriver 路径。Docker 环境使用系统安装的 chromedriver。"""
    if _SYSTEM_CHROMEDRIVER:
        return _SYSTEM_CHROMEDRIVER
    return ChromeDriverManager().install()


@pytest.fixture(scope="function")
def chrome_driver(chromedriver_path):
    """每个测试函数独立的 Chrome/Chromium 实例"""
    options = webdriver.ChromeOptions()
    if _CHROMIUM_BINARY:
        options.binary_location = _CHROMIUM_BINARY
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--ignore-certificate-errors")
    options.add_argument("--test-type")
    d = webdriver.Chrome(service=ChromeService(chromedriver_path), options=options)
    yield d
    d.quit()


@pytest.mark.smoke
class TestSeleniumFramework:
    """验证 Selenium 和 WebDriver 是否正常工作"""

    def test_webdriver_manager_can_download(self, chromedriver_path):
        """WebDriver Manager 或系统安装提供了 ChromeDriver"""
        if _SYSTEM_CHROMEDRIVER:
            pytest.skip("Docker 环境使用系统 chromedriver，跳过 webdriver-manager 下载测试")
        assert chromedriver_path, "ChromeDriver 下载路径不应为空"

    def test_can_create_driver(self, chrome_driver):
        """能创建 Chrome/Chromium 实例"""
        assert chrome_driver is not None

    def test_driver_can_navigate(self, chrome_driver):
        """浏览器能导航到页面"""
        chrome_driver.get("data:text/html,<h1>Hello</h1>")
        assert "Hello" in chrome_driver.page_source
