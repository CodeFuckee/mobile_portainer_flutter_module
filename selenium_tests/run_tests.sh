#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ---- 默认参数 ----
BASE_URL="${TEST_BASE_URL:-http://localhost:8082}"
BROWSER="${TEST_BROWSER:-chrome}"
HEADLESS="${TEST_HEADLESS:-true}"
TEST_TARGET="${1:-tests/}"
PYTEST_ARGS=()

# ---- 解析命令行参数 ----
while [[ $# -gt 0 ]]; do
    case "$1" in
        --base-url=*) BASE_URL="${1#*=}"; shift ;;
        --base-url)   BASE_URL="$2"; shift 2 ;;
        --browser=*)  BROWSER="${1#*=}"; shift ;;
        --browser)    BROWSER="$2"; shift 2 ;;
        --headed)     HEADLESS="false"; shift ;;
        --debug)      HEADLESS="false"; DEBUG="true"; shift ;;
        --smoke)      TEST_TARGET="tests/ -m smoke"; shift ;;
        -k)           PYTEST_ARGS+=("-k" "$2"); shift 2 ;;
        -v)           PYTEST_ARGS+=("-v"); shift ;;
        -s)           PYTEST_ARGS+=("-s"); shift ;;
        --html)       PYTEST_ARGS+=("--html=report.html" "--self-contained-html"); shift ;;
        -h|--help)
            echo "用法: ./run_tests.sh [选项] [测试文件/目录]"
            echo ""
            echo "选项:"
            echo "  --base-url=URL    目标服务器地址 (默认: http://localhost:8082)"
            echo "  --browser=NAME    浏览器: chrome | firefox (默认: chrome)"
            echo "  --headed          显示浏览器窗口"
            echo "  --debug           调试模式：显示浏览器 + 操作间停顿，便于观察"
            echo "  --smoke           仅运行冒烟测试"
            echo "  --html            生成 HTML 报告"
            echo "  -k EXPR           按关键字筛选测试"
            echo "  -v                详细输出"
            echo "  -s                显示 print 输出"
            echo ""
            echo "环境变量:"
            echo "  TEST_BASE_URL     目标服务器地址"
            echo "  TEST_BROWSER      浏览器类型"
            echo "  TEST_HEADLESS     是否无头模式 (true/false)"
            echo "  TEST_USERNAME     Portainer 用户名 (默认: admin)"
            echo "  TEST_PASSWORD     Portainer 密码 (默认: password)"
            echo "  TEST_DEBUG        调试模式 (true/false，默认: false)"
            echo ""
            echo "示例:"
            echo "  ./run_tests.sh"
            echo "  ./run_tests.sh --base-url=http://prod:8082 tests/test_nav_bar.py"
            echo "  ./run_tests.sh --headed --smoke"
            echo "  ./run_tests.sh --html -k nav_bar"
            echo "  ./run_tests.sh --debug          # 调试模式：显示浏览器 + 操作停顿"
            exit 0
            ;;
        *)  TEST_TARGET="$1"; shift ;;
    esac
done

# ---- 创建/检查虚拟环境 ----
if [ ! -d "venv" ]; then
    echo "[setup] 创建虚拟环境..."
    python3 -m venv venv
fi

echo "[setup] 激活虚拟环境..."
source venv/bin/activate

# ---- 安装依赖 ----
if ! python -c "import selenium" 2>/dev/null; then
    echo "[setup] 安装依赖..."
    pip install -r requirements.txt -q
fi

echo "[setup] 依赖 OK"

# ---- 清理可能残留的 webdriver-manager 锁文件 ----
rm -f "$HOME/.wdm/.wdm-lock-"* 2>/dev/null || true

# ---- 服务器连通性检查 ----
echo "[check] 检查服务器连通性: $BASE_URL"
if python -c "
import urllib.request, sys
try:
    req = urllib.request.Request('$BASE_URL', method='GET')
    urllib.request.urlopen(req, timeout=5)
    print('OK')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
" 2>&1; then
    echo "[check] 服务器可达"
else
    echo ""
    echo "============================================="
    echo "  警告: 无法连接到 $BASE_URL"
    echo "  请先启动 Flutter Web 服务:"
    echo ""
    echo "    cd $(dirname "$SCRIPT_DIR")"
    echo "    flutter run -d chrome --web-port 8082"
    echo ""
    echo "  或指定其他地址:"
    echo ""
    echo "    ./run_tests.sh --base-url=http://my-server:8082"
    echo "============================================="
    echo ""
    read -p "是否继续运行测试? [y/N] " yn
    case "$yn" in
        [Yy]* ) ;;
        * ) exit 1 ;;
    esac
fi

# ---- 运行测试 ----
export TEST_BASE_URL="$BASE_URL"
export TEST_BROWSER="$BROWSER"
export TEST_HEADLESS="$HEADLESS"
export TEST_USERNAME="${TEST_USERNAME:-admin}"
export TEST_PASSWORD="${TEST_PASSWORD:-password}"
export TEST_DEBUG="${DEBUG:-false}"

echo ""
echo "=============================="
echo "  目标: $BASE_URL"
echo "  浏览器: $BROWSER"
echo "  Headless: $HEADLESS"
echo "  测试: $TEST_TARGET"
echo "=============================="
echo ""

pytest $TEST_TARGET -v "${PYTEST_ARGS[@]}"
