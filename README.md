# Mindora SDK

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PyPI version](https://badge.fury.io/py/mindora-sdk.svg)](https://badge.fury.io/py/mindora-sdk)

AI基础设施统一SDK，为多个AI应用提供统一的基础服务接口，包括数据库、存储、消息队列、搜索、配置管理等核心功能。

## ✨ 特性

- 🏗️ **统一接口**: 为所有基础设施服务提供一致的API接口
- 🔌 **即插即用**: 通过简单配置即可接入各种基础设施服务
- 🛡️ **类型安全**: 完整的TypeScript风格类型提示和验证
- 🚀 **高性能**: 异步I/O和连接池优化
- 📊 **可观测性**: 内置监控、日志和链路追踪
- 🔧 **易扩展**: 模块化设计，支持自定义客户端
- 🐳 **容器友好**: 完整的Docker Compose基础设施配置

## 🚀 快速开始

### 安装

```bash
# 使用 uv (推荐)
uv add mindora-sdk

# 或使用 pip
pip install mindora-sdk
```

### 基本使用

```python
from mindora_sdk import MindoraSDK

# 初始化SDK
sdk = MindoraSDK(app_name="my_ai_app")

# 数据库操作
from sqlmodel import SQLModel, Field

class User(SQLModel, table=True):
    id: int = Field(primary_key=True)
    username: str
    email: str

# 创建用户
user = sdk.db.create(User, {"username": "john", "email": "john@example.com"})

# 查询用户
user = sdk.db.get_by_id(User, 1)
users = sdk.db.list(User, limit=10)

# 文件存储
file_url = sdk.files.upload("documents", file_data, "document.pdf")
file_content = sdk.files.download("documents", "document.pdf")

# 消息队列
sdk.messages.send_task("ai_processing", {"file_url": file_url})

# 配置管理
api_key = sdk.config.get("openai.api_key")
sdk.config.set("model.temperature", 0.7)

# 搜索功能
results = sdk.search.query("documents", "machine learning")
```

## 🏗️ 架构

```
应用层 (Your AI Apps)
     ↓
适配层 (Mindora SDK)
     ↓
基础设施层 (PostgreSQL, Redis, MinIO, etc.)
```

### 核心组件

- **DBClient**: SQLModel ORM集成，支持多Schema和事务管理
- **FileClient**: MinIO对象存储，文件上传/下载和预签名URL
- **MessageClient**: RabbitMQ消息队列，支持多种消息模式
- **SearchClient**: Elasticsearch和Qdrant搜索功能
- **ConfigClient**: Consul配置管理和动态更新
- **ServiceClient**: Consul服务发现和健康检查

## 🛠️ 开发环境

### 环境要求

- Python 3.10+
- Docker 20.10+
- Docker Compose 2.0+

### 本地开发

```bash
# 克隆项目
git clone https://github.com/mindora/mindora-sdk.git
cd mindora-sdk

# 初始化开发环境
just init

# 启动基础设施
just infra-up

# 运行测试
just test

# 代码检查
just check
```

### 可用命令

```bash
# 查看所有可用命令
just

# 常用命令
just init          # 初始化开发环境
just format        # 格式化代码
just test          # 运行测试
just infra-up      # 启动基础设施
just docs-serve    # 启动文档服务器
```

## 📚 文档

- [快速开始指南](docs/quickstart.md)
- [API文档](docs/api/)
- [架构设计](docs/architecture.md)
- [部署指南](docs/deployment.md)
- [示例代码](examples/)

## 🧪 测试

```bash
# 运行所有测试
just test

# 运行单元测试
just test-unit

# 运行集成测试
just test-integration

# 生成覆盖率报告
just coverage
```

## 📦 发布

```bash
# 构建包
just build

# 发布到测试PyPI
just publish-test

# 发布到正式PyPI
just publish
```

## 🤝 贡献

欢迎贡献代码！请查看 [贡献指南](CONTRIBUTING.md) 了解详细信息。

### 开发流程

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

## 📝 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持

- 📧 邮箱: team@mindora.ai
- 🐛 问题反馈: [GitHub Issues](https://github.com/mindora/mindora-sdk/issues)
- 💬 讨论: [GitHub Discussions](https://github.com/mindora/mindora-sdk/discussions)

## 🗺️ 路线图

- [ ] 支持更多数据库类型 (MySQL, MongoDB)
- [ ] 集成更多向量数据库 (Pinecone, Weaviate)
- [ ] 添加分布式缓存支持
- [ ] 实现自动化故障恢复
- [ ] 支持Kubernetes部署
- [ ] 添加GraphQL支持