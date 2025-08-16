# Mindora SDK 开发自动化脚本
# 使用 `just` 命令查看所有可用命令

# 设置默认shell
set shell := ["bash", "-c"]

# 默认任务
default:
    @just --list

# === 环境管理 ===

# 初始化开发环境
init:
    @echo "🚀 初始化 Mindora SDK 开发环境..."
    uv sync --dev
    uv run pre-commit install
    @echo "✅ 开发环境初始化完成"

# 同步依赖
sync:
    @echo "📦 同步项目依赖..."
    uv sync

# 添加依赖
add package:
    @echo "➕ 添加依赖: {{package}}"
    uv add {{package}}

# 添加开发依赖
add-dev package:
    @echo "➕ 添加开发依赖: {{package}}"
    uv add --dev {{package}}

# 清理环境
clean:
    @echo "🧹 清理环境..."
    rm -rf .pytest_cache/
    rm -rf .coverage
    rm -rf htmlcov/
    rm -rf dist/
    rm -rf build/
    rm -rf *.egg-info/
    find . -type d -name __pycache__ -exec rm -rf {} +
    find . -type f -name "*.pyc" -delete
    @echo "✅ 清理完成"

# === 代码质量 ===

# 运行所有代码检查
check: format lint type test
    @echo "✅ 所有检查通过"

# 格式化代码
format:
    @echo "🎨 格式化代码..."
    uv run ruff format .
    uv run ruff check --fix .

# 代码检查
lint:
    @echo "🔍 运行代码检查..."
    uv run ruff check .

# 类型检查
type:
    @echo "🔎 运行类型检查..."
    uv run mypy mindora_sdk/

# Pre-commit检查
pre-commit:
    @echo "🔒 运行 pre-commit 检查..."
    uv run pre-commit run --all-files

# === 测试 ===

# 运行所有测试
test:
    @echo "🧪 运行测试套件..."
    uv run pytest

# 运行单元测试
test-unit:
    @echo "🧪 运行单元测试..."
    uv run pytest tests/unit/ -v

# 运行集成测试
test-integration:
    @echo "🧪 运行集成测试..."
    uv run pytest tests/integration/ -v

# 运行性能测试
test-performance:
    @echo "🚀 运行性能测试..."
    uv run pytest tests/performance/ -v

# 测试覆盖率报告
coverage:
    @echo "📊 生成测试覆盖率报告..."
    uv run pytest --cov=mindora_sdk --cov-report=html --cov-report=term

# 监控测试文件变化并自动运行
test-watch:
    @echo "👀 监控文件变化并自动运行测试..."
    uv run pytest-watch -- tests/

# === 构建和发布 ===

# 构建包
build:
    @echo "📦 构建 Python 包..."
    uv build

# 检查包
check-package:
    @echo "🔍 检查包完整性..."
    uv run twine check dist/*

# 发布到测试PyPI
publish-test: build check-package
    @echo "🚀 发布到测试 PyPI..."
    uv run twine upload --repository testpypi dist/*

# 发布到正式PyPI
publish: build check-package
    @echo "🚀 发布到正式 PyPI..."
    uv run twine upload dist/*

# === 基础设施管理 ===

# 启动开发环境基础设施
infra-up:
    @echo "🐳 启动开发环境基础设施..."
    cd infrastructure/docker && docker-compose -f docker-compose.dev.yml up -d

# 停止基础设施
infra-down:
    @echo "🛑 停止基础设施..."
    cd infrastructure/docker && docker-compose -f docker-compose.dev.yml down

# 重启基础设施
infra-restart:
    @echo "🔄 重启基础设施..."
    just infra-down
    just infra-up

# 查看基础设施状态
infra-status:
    @echo "📊 基础设施状态..."
    cd infrastructure/docker && docker-compose -f docker-compose.dev.yml ps

# 查看基础设施日志
infra-logs service="":
    @echo "📋 查看基础设施日志..."
    cd infrastructure/docker && docker-compose -f docker-compose.dev.yml logs {{service}}

# 创建基础设施数据目录
infra-init:
    @echo "📁 创建基础设施数据目录..."
    mkdir -p ~/.mindora/infrastructure/{postgres,redis,minio,rabbitmq,elasticsearch,qdrant,consul,prometheus,grafana}
    @echo "✅ 数据目录创建完成"

# === 文档 ===

# 生成API文档
docs-api:
    @echo "📚 生成API文档..."
    uv run pdoc --html --output-dir docs/api mindora_sdk

# 构建文档
docs-build:
    @echo "📖 构建项目文档..."
    uv run mkdocs build

# 启动文档服务器
docs-serve:
    @echo "📖 启动文档服务器..."
    uv run mkdocs serve

# === 示例和开发 ===

# 运行基础示例
example-basic:
    @echo "🎯 运行基础示例..."
    cd examples/basic && uv run python main.py

# 运行高级示例
example-advanced:
    @echo "🎯 运行高级示例..."
    cd examples/advanced && uv run python main.py

# 运行生产示例
example-production:
    @echo "🎯 运行生产示例..."
    cd examples/production && uv run python main.py

# === 数据库管理 ===

# 创建数据库迁移
migration name:
    @echo "📊 创建数据库迁移: {{name}}"
    uv run alembic revision --autogenerate -m "{{name}}"

# 运行数据库迁移
migrate:
    @echo "📊 运行数据库迁移..."
    uv run alembic upgrade head

# 回滚数据库迁移
migrate-downgrade steps="1":
    @echo "📊 回滚数据库迁移..."
    uv run alembic downgrade -{{steps}}

# === 安全和依赖检查 ===

# 安全漏洞扫描
security:
    @echo "🔒 运行安全扫描..."
    uv run bandit -r mindora_sdk/
    uv run safety check

# 检查过期依赖
deps-check:
    @echo "📦 检查过期依赖..."
    uv run pip list --outdated

# === 性能分析 ===

# 性能分析
profile script:
    @echo "⚡ 运行性能分析..."
    uv run python -m cProfile -o profile.stats {{script}}
    uv run python -c "import pstats; pstats.Stats('profile.stats').sort_stats('cumulative').print_stats(20)"

# === 工具和实用程序 ===

# 检查项目健康状态
health:
    @echo "🏥 检查项目健康状态..."
    @echo "Python版本:" && python --version
    @echo "UV版本:" && uv --version
    @echo "Git状态:" && git status --porcelain
    @echo "依赖状态:" && uv pip check || echo "⚠️  发现依赖问题"

# 生成需求文件
requirements:
    @echo "📋 生成 requirements.txt..."
    uv pip freeze > requirements.txt

# 更新所有依赖到最新版本
update-deps:
    @echo "⬆️  更新所有依赖..."
    uv sync --upgrade

# 项目统计信息
stats:
    @echo "📊 项目统计信息..."
    @echo "代码行数:"
    find mindora_sdk -name "*.py" | xargs wc -l | tail -n 1
    @echo "测试行数:"
    find tests -name "*.py" | xargs wc -l | tail -n 1
    @echo "文件总数:"
    find . -name "*.py" | wc -l