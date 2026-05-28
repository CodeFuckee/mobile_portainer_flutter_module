import time

from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from pages import BasePage
from config import debug_sleep


class LoginPage(BasePage):
    """Flutter CanvasKit 登录页 — 通过键盘交互操作。"""

    TEXT_EDITING_INPUT = (By.CSS_SELECTOR, "input.flt-text-editing")
    USERNAME_INPUT = TEXT_EDITING_INPUT
    LOGIN_BUTTON = (By.XPATH, '//flt-semantics[contains(text(),"Login") or contains(text(),"登录")]')

    def _get_active_input(self):
        inputs = self.driver.find_elements(*self.TEXT_EDITING_INPUT)
        if not inputs:
            raise Exception("找不到 Flutter 文本编辑 input")
        return inputs[-1]

    def enter_username(self, username: str):
        debug_sleep(1)
        inp = self._get_active_input()
        inp.clear()
        inp.send_keys(username)
        debug_sleep(1.5)

    def enter_password(self, password: str):
        inp = self._get_active_input()
        inp.send_keys(Keys.TAB)
        time.sleep(0.3)
        debug_sleep(1)
        inp = self._get_active_input()
        inp.clear()
        inp.send_keys(password)
        debug_sleep(1.5)

    def click_login(self):
        debug_sleep(1)
        inp = self._get_active_input()
        inp.send_keys(Keys.ENTER)
        debug_sleep(2)

    def login(self, username: str, password: str):
        self.enter_username(username)
        time.sleep(0.5)
        self.enter_password(password)
        time.sleep(0.5)
        self.click_login()
