# Feature Design: Docker Compose 基础设施配置

## 1. Overview

设计并实现完整的Docker Compose基础设施配置系统，为mindora_sdk项目提供一键部署的AI基础设施环境，支持开发、测试、生产多环境，包含数据存储、消息队列、搜索引擎、服务发现、监控等全栈基础设施服务。

## 2. Data Structures

### 2.1 环境配置结构

```yaml
# .env 环境变量配置
MINDORA_DATA_ROOT: string          # 数据持久化根目录路径
POSTGRES_DB: string                # PostgreSQL数据库名
POSTGRES_USER: string              # PostgreSQL用户名
POSTGRES_PASSWORD: string          # PostgreSQL密码
REDIS_PASSWORD: string             # Redis密码
MINIO_ROOT_USER: string            # MinIO管理员用户名
MINIO_ROOT_PASSWORD: string        # MinIO管理员密码
RABBITMQ_DEFAULT_USER: string      # RabbitMQ用户名
RABBITMQ_DEFAULT_PASS: string      # RabbitMQ密码
GRAFANA_ADMIN_PASSWORD: string     # Grafana管理员密码
```

### 2.2 服务配置对象

```typescript
interface ServiceConfig {
  name: string;                     // 服务名称
  image: string;                    // Docker镜像
  ports: string[];                  // 端口映射
  volumes: string[];                // 数据卷挂载
  environment: Record<string, string>; // 环境变量
  healthcheck: HealthCheck;         // 健康检查配置
  dependencies: string[];           // 服务依赖
}

interface HealthCheck {
  test: string;                     // 健康检查命令
  interval: string;                 // 检查间隔
  timeout: string;                  // 超时时间
  retries: number;                  // 重试次数
}
```

### 2.3 环境配置矩阵

```yaml
environments:
  development:
    resource_limits: false          # 不限制资源
    debug_ports: true              # 暴露调试端口
    data_persistence: local        # 本地数据持久化
    logging_level: debug           # 调试日志级别
    
  testing:
    resource_limits: true          # 限制资源使用
    debug_ports: false             # 不暴露调试端口
    data_persistence: memory       # 内存数据存储
    logging_level: info            # 标准日志级别
    
  production:
    resource_limits: true          # 严格资源限制
    debug_ports: false             # 禁用调试端口
    data_persistence: volume       # 专用数据卷
    logging_level: warn            # 警告日志级别
```

## 3. Interfaces (REST API)

### 3.1 服务管理接口

```bash
# 环境管理
GET /health                        # 全局健康检查
GET /services                      # 服务状态列表
GET /services/{service}/health     # 单个服务健康状态
POST /services/{service}/restart   # 重启指定服务
POST /services/restart-all         # 重启所有服务

# 配置管理
GET /config                        # 获取当前配置
PUT /config                        # 更新配置
POST /config/reload               # 重载配置

# 监控数据
GET /metrics                       # Prometheus指标
GET /logs/{service}               # 服务日志
```

### 3.2 服务端口映射

```yaml
external_ports:
  nginx: [80, 443]                 # Web代理
  postgres: [5432]                 # 数据库
  redis: [6379]                    # 缓存
  minio: [9000, 9001]             # 对象存储 (API + Console)
  rabbitmq: [5672, 15672]         # 消息队列 (AMQP + Management)
  elasticsearch: [9200, 9300]     # 搜索引擎 (HTTP + Transport)
  qdrant: [6333]                   # 向量数据库
  consul: [8500, 8600]            # 服务发现 (HTTP + DNS)
  prometheus: [9090]               # 监控数据
  grafana: [3000]                  # 监控界面
  kibana: [5601]                   # 日志分析界面
```

## 4. Functional Description

### 4.1 核心工作流程

#### 环境初始化流程
1. **环境检查**: 验证Docker Engine和Docker Compose版本
2. **配置准备**: 复制 `.env.example` 到 `.env` 并验证配置完整性
3. **目录创建**: 自动创建数据持久化目录结构
4. **权限设置**: 确保数据目录具有正确的读写权限

#### 服务启动流程
1. **网络创建**: 建立 `mindora_network` 内部网络
2. **基础服务启动**: 按依赖顺序启动数据库、缓存等基础服务
3. **应用服务启动**: 启动搜索、消息队列等应用层服务
4. **监控服务启动**: 最后启动监控和管理界面服务
5. **健康检查**: 等待所有服务通过健康检查

#### 服务发现和配置管理
1. **Consul注册**: 自动将服务注册到Consul服务发现
2. **配置分发**: 通过Consul KV存储分发配置到各个服务
3. **动态更新**: 支持运行时动态更新配置
4. **状态监控**: 持续监控服务状态和连通性

### 4.2 多环境配置策略

#### 开发环境 (docker-compose.dev.yml)
- **特点**: 完全的端口暴露，便于调试和开发
- **数据持久化**: 挂载到 `~/.mindora/infrastructure/` 目录
- **资源限制**: 无限制，充分利用开发机器资源
- **日志级别**: DEBUG，详细的调试信息

#### 测试环境 (docker-compose.test.yml)
- **特点**: CI/CD优化，快速启动和清理
- **数据持久化**: 临时内存存储，测试后自动清理
- **资源限制**: 适中限制，确保测试环境稳定
- **日志级别**: INFO，标准信息输出

#### 生产环境 (docker-compose.prod.yml)
- **特点**: 安全性和稳定性优先
- **数据持久化**: 专用数据卷，备份策略完整
- **资源限制**: 严格限制，防止资源竞争
- **日志级别**: WARN，仅输出警告和错误

### 4.3 数据持久化和备份策略

#### 数据目录结构
```
~/.mindora/infrastructure/
├── postgres/                      # PostgreSQL数据
├── redis/                         # Redis持久化数据
├── minio/                         # MinIO对象存储
├── consul/                        # Consul数据和配置
├── elasticsearch/                 # ES索引数据
├── qdrant/                        # 向量数据
├── prometheus/                    # 监控数据
├── grafana/                       # 仪表板配置
├── rabbitmq/                      # 消息队列数据
└── backups/                       # 自动备份文件
    ├── daily/                     # 每日备份
    ├── weekly/                    # 每周备份
    └── monthly/                   # 每月备份
```

#### 备份和恢复机制
1. **自动备份**: 每日凌晨自动备份关键数据
2. **增量备份**: 支持增量备份减少存储空间
3. **多版本保留**: 保留30天内的每日备份、12周的周备份、12个月的月备份
4. **一键恢复**: 提供脚本支持从备份快速恢复

## 5. Involved File List

### 创建文件
- `create`: `infrastructure/docker/docker-compose.test.yml` - 测试环境配置
- `create`: `infrastructure/docker/docker-compose.prod.yml` - 生产环境配置
- `create`: `infrastructure/docker/.env.example` - 环境变量模板
- `create`: `infrastructure/docker/nginx/nginx.conf` - Nginx配置
- `create`: `infrastructure/configs/prometheus/prometheus.yml` - Prometheus配置
- `create`: `infrastructure/configs/grafana/datasources/prometheus.yml` - Grafana数据源
- `create`: `infrastructure/configs/grafana/dashboards/mindora-overview.json` - 监控仪表板
- `create`: `infrastructure/configs/consul/server.json` - Consul服务器配置
- `create`: `infrastructure/init/postgres/01-create-schemas.sql` - 数据库Schema初始化
- `create`: `infrastructure/init/postgres/02-init-data.sql` - 初始数据
- `create`: `infrastructure/init/consul/kv-init.json` - Consul KV初始化
- `create`: `infrastructure/scripts/setup.sh` - 环境初始化脚本
- `create`: `infrastructure/scripts/backup.sh` - 数据备份脚本
- `create`: `infrastructure/scripts/restore.sh` - 数据恢复脚本
- `create`: `infrastructure/scripts/health-check.sh` - 健康检查脚本
- `create`: `infrastructure/scripts/deploy.sh` - 部署脚本

### 修改文件
- `modify`: `infrastructure/docker/docker-compose.dev.yml` - 更新版本和配置优化
- `modify`: `justfile` - 添加基础设施管理命令
- `modify`: `.gitignore` - 添加基础设施数据忽略规则

### 删除文件
无需删除文件

## 6. Risks and Trade-offs

### 6.1 技术风险

#### 版本兼容性风险
- **风险**: 升级到最新版本可能导致不兼容
- **缓解**: 提供版本回退机制，保留当前稳定版本配置

#### 资源消耗风险
- **风险**: 全服务栈可能消耗大量系统资源
- **缓解**: 提供最小化配置，支持选择性启动服务

#### 网络端口冲突
- **风险**: 端口占用可能导致服务启动失败
- **缓解**: 提供端口检查脚本，支持自定义端口配置

### 6.2 运维风险

#### 数据安全风险
- **风险**: 开发环境可能暴露敏感数据
- **缓解**: 使用环境变量管理敏感配置，提供数据加密选项

#### 备份失败风险
- **风险**: 自动备份可能失败导致数据丢失
- **缓解**: 多重备份策略，备份状态监控和告警

### 6.3 设计权衡

#### 功能完整性 vs 启动速度
- **权衡**: 全功能服务栈启动时间较长
- **选择**: 提供快速启动模式，仅启动核心服务

#### 开发便利性 vs 安全性
- **权衡**: 开发环境暴露端口 vs 生产环境安全性
- **选择**: 按环境分离配置，开发便利但生产安全

## 7. Testing Strategy

### 7.1 单元测试

#### Docker Compose配置验证
- **测试内容**: 配置文件语法正确性
- **工具**: `docker-compose config` 命令验证
- **覆盖范围**: 所有环境配置文件

#### 环境变量验证
- **测试内容**: 环境变量完整性和格式
- **工具**: 自定义验证脚本
- **覆盖范围**: 所有必需环境变量

```bash
# 配置验证测试
test_compose_config() {
  docker-compose -f docker-compose.dev.yml config --quiet
  docker-compose -f docker-compose.test.yml config --quiet
  docker-compose -f docker-compose.prod.yml config --quiet
}

test_env_variables() {
  source .env.example
  check_required_vars "POSTGRES_DB" "POSTGRES_USER" "POSTGRES_PASSWORD"
}
```

### 7.2 集成测试

#### 服务启动测试
- **测试内容**: 所有服务能够成功启动并通过健康检查
- **工具**: Docker Compose + 健康检查脚本
- **超时设置**: 5分钟启动超时

#### 服务间连通性测试
- **测试内容**: 验证服务间网络连通性和API可访问性
- **工具**: curl + 自定义连通性测试脚本

```bash
# 集成测试示例
test_service_connectivity() {
  # 测试数据库连接
  docker exec mindora_postgres pg_isready -U $POSTGRES_USER
  
  # 测试Redis连接
  docker exec mindora_redis redis-cli -a $REDIS_PASSWORD ping
  
  # 测试API端点
  curl -f http://localhost:9000/minio/health/live
  curl -f http://localhost:9200/_cluster/health
}
```

### 7.3 端到端测试

#### 完整工作流测试
- **测试场景**: 模拟完整的应用开发工作流
- **包含内容**: 
  - 环境初始化
  - 服务启动
  - 数据操作
  - 监控验证
  - 服务停止和清理

#### 故障恢复测试
- **测试场景**: 模拟服务故障和恢复
- **包含内容**:
  - 单个服务故障恢复
  - 网络分区恢复
  - 数据备份和恢复

```python
# E2E测试示例
def test_full_workflow():
    # 1. 环境初始化
    run_command("./infrastructure/scripts/setup.sh")
    
    # 2. 启动服务
    run_command("just infra-up")
    wait_for_services_healthy()
    
    # 3. 验证功能
    test_database_operations()
    test_object_storage()
    test_message_queue()
    test_search_functionality()
    
    # 4. 监控验证
    verify_metrics_collection()
    verify_log_aggregation()
    
    # 5. 清理
    run_command("just infra-down")
```

### 7.4 性能测试

#### 启动时间测试
- **目标**: 开发环境5分钟内启动完成
- **测量**: 从启动到所有服务健康检查通过的时间

#### 资源使用测试
- **目标**: 确保资源使用在合理范围内
- **测量**: CPU、内存、磁盘和网络使用率

### 7.5 安全测试

#### 端口暴露测试
- **验证**: 仅预期端口对外暴露
- **工具**: nmap端口扫描

#### 配置安全测试
- **验证**: 敏感信息不在配置文件中硬编码
- **工具**: 静态配置扫描

所有测试应当在CI/CD流程中自动执行，确保每次代码变更都经过完整的测试验证。测试失败时应提供详细的错误信息和恢复建议。