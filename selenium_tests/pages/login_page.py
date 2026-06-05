import time

from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from pages import BasePage
from config import debug_sleep


class LoginPage(BasePage):
    """Flutter CanvasKit 登录页 — 通过键盘交互操作。"""

    TEXT_EDITING_INPUT = (By.CSS_SELECTOR, "input.flt-text-editing")
    USERNAME_SEMANTICS = (By.XPATH, '//flt-semantics[contains(@role,"text")]')
    USERNAME_INPUT = USERNAME_SEMANTICS
    LOGIN_BUTTON = (By.XPATH, '//flt-semantics[contains(text(),"Login") or contains(text(),"登录")]')

    def _focus_first_textfield(self):
        """点击第一个 Flutter 文本字段使其获得焦点，创建 input.flt-text-editing 元素。"""
        selectors = [
            '//flt-semantics[@role="textbox"]',
            '//flt-semantics[contains(@role, "text")]',
        ]
        for xpath in selectors:
            try:
                el = self.driver.find_element(By.XPATH, xpath)
                self.driver.execute_script("""
                    arguments[0].scrollIntoView(true);
                    arguments[0].click();
                    arguments[0].dispatchEvent(new MouseEvent("click", {bubbles: true}));
                    arguments[0].dispatchEvent(new PointerEvent("pointerdown", {bubbles: true}));
                    arguments[0].dispatchEvent(new PointerEvent("pointerup", {bubbles: true}));
                """, el)
                time.sleep(1)
                return
            except Exception:
                continue

        # 回退：点击 glass-pane 上部区域（用户名输入框通常在上方）
        try:
            gp = self.driver.find_element(By.CSS_SELECTOR, "flt-glass-pane")
            self.driver.execute_script("""
                const gp = arguments[0];
                gp.style.pointerEvents = 'auto';
                const rect = gp.getBoundingClientRect();
                const cx = rect.left + rect.width / 2;
                const cy = rect.top + rect.height * 0.3;
                const el = document.elementFromPoint(cx, cy);
                if (el) {
                    el.click();
                    el.dispatchEvent(new MouseEvent("click", {bubbles: true}));
                    el.dispatchEvent(new PointerEvent("pointerdown", {bubbles: true}));
                    el.dispatchEvent(new PointerEvent("pointerup", {bubbles: true}));
                }
            """, gp)
            time.sleep(1)
        except Exception:
            pass

    def _get_active_input(self):
        """获取当前活跃的 Flutter 文本编辑 input 元素。

        Docker 环境下 Chromium 不会自动聚焦文本字段，需要先点击
        Flutter 语义节点来触发输入框获得焦点。
        """
        inputs = self.driver.find_elements(*self.TEXT_EDITING_INPUT)
        if not inputs:
            self._focus_first_textfield()
            try:
                WebDriverWait(self.driver, 5).until(
                    EC.presence_of_element_located(self.TEXT_EDITING_INPUT)
                )
                inputs = self.driver.find_elements(*self.TEXT_EDITING_INPUT)
            except Exception:
                pass
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
