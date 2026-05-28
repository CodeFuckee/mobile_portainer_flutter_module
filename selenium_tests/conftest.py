import socket
import time
import urllib.request
from urllib.parse import urlparse

import time

import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.firefox.service import Service as FirefoxService
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.firefox import GeckoDriverManager
from config import BASE_URL, IMPLICIT_WAIT, PAGE_LOAD_TIMEOUT, BROWSER, HEADLESS, TEST_USERNAME, TEST_PASSWORD

# 底部导航标签名，供所有测试复用
TAB_NAMES = ["Dashboard", "Containers", "Resources", "Settings"]


def _is_server_reachable(url: str, timeout: int = 3) -> bool:
    try:
        parsed = urlparse(url)
        host = parsed.hostname or "localhost"
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        s = socket.create_connection((host, port), timeout=timeout)
        s.close()
        return True
    except Exception:
        return False


def _try_http(url: str, timeout: int = 5) -> bool:
    try:
        req = urllib.request.Request(url, method="GET")
        urllib.request.urlopen(req, timeout=timeout)
        return True
    except Exception:
        return False


def enable_flutter_semantics(driver):
    """启用 Flutter 无障碍语义树，使 CanvasKit 应用的 widget 可通过 DOM 访问。"""
    # 先禁用 glass-pane 的鼠标拦截，否则无法点击语义占位符
    driver.execute_script("""
        const gp = document.querySelector('flt-glass-pane');
        if (gp) {
            gp.style.pointerEvents = 'none';
            const canvas = gp.shadowRoot?.querySelector('canvas');
            if (canvas) canvas.style.pointerEvents = 'none';
        }
    """)
    time.sleep(0.5)

    # 点击语义占位符启用无障碍树
    for _ in range(5):
        driver.execute_script(
            'document.querySelector("flt-semantics-placeholder")?.click();'
        )
        time.sleep(1)
        children = driver.execute_script(
            'return document.querySelector("flt-semantics-host")?.children.length || 0;'
        )
        if children > 0:
            break

    time.sleep(1)


def _wait_flutter_ready(driver, timeout: int = 60):
    """等待 Flutter 应用渲染完成（flutter-view 元素出现）。"""
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC

    try:
        WebDriverWait(driver, timeout).until(
            EC.presence_of_element_located((By.CSS_SELECTOR, "flutter-view"))
        )
        time.sleep(3)
    except Exception:
        pass  # 超时不算致命错误，继续执行测试


def _create_chrome_driver():
    options = webdriver.ChromeOptions()
    if HEADLESS:
        options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--incognito")
    options.add_argument("--enable-unsafe-swiftshader")
    options.add_argument("--window-size=1920,1080")
    return webdriver.Chrome(
        service=ChromeService(ChromeDriverManager().install()), options=options
    )


def _create_firefox_driver():
    options = webdriver.FirefoxOptions()
    if HEADLESS:
        options.add_argument("--headless")
    options.add_argument("--window-size=1920,1080")
    return webdriver.Firefox(
        service=FirefoxService(GeckoDriverManager().install()), options=options
    )


@pytest.fixture(scope="session")
def base_url():
    return BASE_URL


@pytest.fixture(scope="session")
def server_reachable(base_url):
    return _is_server_reachable(base_url) and _try_http(base_url)


@pytest.fixture(scope="function")
def driver(base_url, server_reachable):
    if not server_reachable:
        pytest.skip(f"服务器不可达: {base_url}")

    if BROWSER == "firefox":
        d = _create_firefox_driver()
    else:
        d = _create_chrome_driver()
    d.implicitly_wait(IMPLICIT_WAIT)
    d.set_page_load_timeout(PAGE_LOAD_TIMEOUT)
    try:
        d.get(base_url)
    except Exception as e:
        d.quit()
        pytest.skip(f"无法打开页面 {base_url}: {e}")

    _wait_flutter_ready(d)
    enable_flutter_semantics(d)

    from config import debug_sleep
    debug_sleep(2)

    yield d
    d.quit()


@pytest.fixture(autouse=False)
def do_login(driver):
    """登录 fixture — 需要登录的测试类通过 autouse=True 引用。"""
    from pages.login_page import LoginPage
    from pages.nav_bar import NavBar

    page = LoginPage(driver)
    try:
        page.login(TEST_USERNAME, TEST_PASSWORD)
    except Exception as e:
        pytest.skip(f"登录交互失败: {e}")
    time.sleep(5)

    nav = NavBar(driver)
    if not nav.is_visible():
        pytest.skip(
            "登录失败，主界面导航栏不可用。"
            "请确认后端已运行且 TEST_USERNAME/TEST_PASSWORD 环境变量正确。"
        )
