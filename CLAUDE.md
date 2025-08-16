# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

mindora_sdk 是一个AI基础设施Python SDK，为多个AI应用提供统一的基础服务接口，包括数据库、存储、消息队列、搜索、配置管理等核心功能。

## 依赖管理

- 使用 `uv` 管理Python依赖：`uv add package_name`、`uv sync`
- 使用 `npm` 管理JavaScript依赖（如果有前端组件）

## 技术栈

- **后端框架**: Python + FastAPI
- **ORM**: SQLModel（替代SQLAlchemy，提供类型安全）
- **数据库**: PostgreSQL（主数据库）+ Redis（缓存）
- **对象存储**: MinIO
- **向量数据库**: Qdrant
- **搜索引擎**: Elasticsearch
- **消息队列**: RabbitMQ + RQ（任务队列）
- **服务发现**: Consul
- **监控**: Prometheus + Grafana
- **容器化**: Docker + Docker Compose

## 核心架构

SDK采用分层架构：
```
应用层 → 适配层（SDK）→ 基础设施层
```

### 主要客户端组件

1. **DBClient**: SQLModel ORM集成，支持多Schema和事务管理
2. **FileClient**: MinIO对象存储，文件上传/下载和预签名URL
3. **MessageClient**: RabbitMQ消息队列，支持多种消息模式
4. **SearchClient**: Elasticsearch和Qdrant搜索功能
5. **ConfigClient**: Consul配置管理和动态更新
6. **ServiceClient**: Consul服务发现和健康检查

## 数据模型设计原则

- **Schemas vs Entities 区分**:
  - `schemas.py`: Pydantic模型，用于API请求/响应验证
  - `entities.py`: SQLModel模型，用于数据库ORM映射
- 避免在同一文件中混合API模型和数据库模型

## 基础设施服务隔离

- **数据库**: PostgreSQL Schema级别隔离
- **对象存储**: MinIO按bucket隔离  
- **向量数据**: Qdrant按collection隔离
- **搜索索引**: Elasticsearch按index隔离
- **消息队列**: RabbitMQ按queue隔离

## 开发原则

1. **业务无关性**: 基础设施服务必须与具体业务逻辑解耦
2. **技术中性**: 使用纯技术概念，避免业务领域术语
3. **依赖层次**: 业务层→基础设施层（单向依赖）
4. **配置驱动**: 支持通过配置文件切换不同环境
5. **错误处理**: 统一的错误处理和重试机制

## 性能要求

- API响应时间：95%请求<2秒
- 文件上传：支持100MB文件<30秒
- 搜索查询：复杂查询<5秒
- 并发支持：100并发用户
- 可用性：99%+

## 安全要求

- 数据传输必须使用HTTPS
- 敏感配置加密存储
- 应用间数据严格隔离
- 基于角色的访问控制(RBAC)
- 审计日志全覆盖

## SDK使用示例

```python
from mindora_sdk import MindoraSDK

# 初始化SDK
sdk = MindoraSDK(app_name="user_service")

# 数据库操作
user = sdk.db.get_by_id(User, user_id)
sdk.db.create(User, {"username": "john"})

# 配置管理
api_key = sdk.config.get("openai.api_key")

# 文件操作
file_url = sdk.files.upload("documents", file_data)

# 消息发送
sdk.messages.send_task("ai_processing", {"file_url": file_url})

# 搜索操作
results = sdk.search.query("documents", "search term")
```

## 测试策略

- 将测试脚本保存到项目根目录下的 `tests/` 目录
- 单元测试覆盖所有客户端组件
- 集成测试验证端到端业务流程
- 性能测试确保满足指标要求

## 部署架构

- 单机Docker Compose部署，适合5-10人团队
- 所有配置通过.env文件管理
- 数据持久化通过宿主机目录挂载
- 内部Docker网络，最小化外部端口暴露