import time

import pytest
from pages.nav_bar import NavBar
from conftest import TAB_NAMES


@pytest.fixture(autouse=True)
def login(do_login):
    yield


class TestNavBar:
    """底部导航栏综合测试。"""

    def test_nav_bar_exists_and_has_tabs(self, driver):
        nav = NavBar(driver)
        assert nav.is_visible(), "主界面应显示底部导航栏"

        found = [t for t in TAB_NAMES if nav.tab_exists(t)]
        assert len(found) >= 2, f"应至少找到 2 个导航标签，实际找到: {found}"

    def test_nav_bar_visible_after_scroll(self, driver):
        nav = NavBar(driver)

        driver.execute_script("window.scrollBy(0, 600)")
        time.sleep(1)
        assert nav.is_visible(), "滚动后导航栏应仍然可见"

        driver.execute_script("window.scrollBy(0, -600)")
        time.sleep(1)
        assert nav.is_visible(), "滚回顶部后导航栏应仍然可见"
