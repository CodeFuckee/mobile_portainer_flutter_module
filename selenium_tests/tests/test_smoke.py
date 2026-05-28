"""冒烟测试 — 不依赖目标服务器的框架验证"""

import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager


@pytest.fixture(scope="session")
def chromedriver_path():
    """会话级别：只下载一次 ChromeDriver"""
    return ChromeDriverManager().install()


@pytest.fixture(scope="function")
def chrome_driver(chromedriver_path):
    """每个测试函数独立的 Chrome 实例"""
    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    d = webdriver.Chrome(service=ChromeService(chromedriver_path), options=options)
    yield d
    d.quit()


@pytest.mark.smoke
class TestSeleniumFramework:
    """验证 Selenium 和 WebDriver 是否正常工作"""

    def test_webdriver_manager_can_download(self, chromedriver_path):
        """WebDriver Manager 能下载 ChromeDriver"""
        assert chromedriver_path, "ChromeDriver 下载路径不应为空"

    def test_can_create_driver(self, chrome_driver):
        """能创建 Chrome 实例"""
        assert chrome_driver is not None

    def test_driver_can_navigate(self, chrome_driver):
        """浏览器能导航到页面"""
        chrome_driver.get("data:text/html,<h1>Hello</h1>")
        assert "Hello" in chrome_driver.page_source
