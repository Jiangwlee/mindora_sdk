#!/bin/bash
# Mindora SDK 基础设施环境初始化脚本
# 自动创建必要的目录结构和配置文件

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装或版本过低，请安装 Docker Compose V2"
        exit 1
    fi
    
    # 检查可用内存
    total_mem=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_mem" -lt 4096 ]; then
        log_warning "系统内存少于4GB，可能影响服务性能"
    fi
    
    # 检查可用磁盘空间
    available_space=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$available_space" -lt 20 ]; then
        log_warning "可用磁盘空间少于20GB，可能影响数据存储"
    fi
    
    log_success "系统要求检查完成"
}

# 创建数据目录
create_data_directories() {
    log_info "创建数据持久化目录..."
    
    # 默认数据根目录
    MINDORA_DATA_ROOT="${MINDORA_DATA_ROOT:-$HOME/.mindora/infrastructure}"
    
    # 创建主目录
    mkdir -p "$MINDORA_DATA_ROOT"
    
    # 创建各服务数据目录
    local services=(
        "postgres"
        "redis" 
        "minio"
        "rabbitmq"
        "elasticsearch"
        "qdrant"
        "consul"
        "prometheus"
        "grafana"
        "kibana"
        "nginx/logs"
        "backups/daily"
        "backups/weekly"
        "backups/monthly"
    )
    
    for service in "${services[@]}"; do
        mkdir -p "$MINDORA_DATA_ROOT/$service"
        log_info "创建目录: $MINDORA_DATA_ROOT/$service"
    done
    
    # 设置适当的权限
    chmod -R 755 "$MINDORA_DATA_ROOT"
    
    # 为特定服务设置特殊权限
    chmod 777 "$MINDORA_DATA_ROOT/elasticsearch" 2>/dev/null || true
    chmod 777 "$MINDORA_DATA_ROOT/grafana" 2>/dev/null || true
    
    log_success "数据目录创建完成: $MINDORA_DATA_ROOT"
}

# 生成环境配置文件
setup_environment() {
    log_info "设置环境配置..."
    
    local env_file="./infrastructure/docker/.env"
    
    # 如果.env文件不存在，从示例文件复制
    if [ ! -f "$env_file" ]; then
        if [ -f "./infrastructure/docker/.env.example" ]; then
            cp "./infrastructure/docker/.env.example" "$env_file"
            log_info "从 .env.example 创建 .env 文件"
        else
            log_error ".env.example 文件不存在"
            exit 1
        fi
    else
        log_info ".env 文件已存在，跳过创建"
    fi
    
    # 更新数据根目录路径
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|MINDORA_DATA_ROOT=.*|MINDORA_DATA_ROOT=${MINDORA_DATA_ROOT:-$HOME/.mindora/infrastructure}|" "$env_file"
    else
        # Linux
        sed -i "s|MINDORA_DATA_ROOT=.*|MINDORA_DATA_ROOT=${MINDORA_DATA_ROOT:-$HOME/.mindora/infrastructure}|" "$env_file"
    fi
    
    log_success "环境配置完成"
}

# 生成安全密钥
generate_secrets() {
    log_info "生成安全密钥..."
    
    local env_file="./infrastructure/docker/.env"
    
    # 生成随机密码的函数
    generate_password() {
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
    }
    
    # 如果密码字段为默认值，则生成新密码
    if grep -q "change_me" "$env_file"; then
        log_info "检测到默认密码，生成新的安全密钥..."
        
        # 替换各种密码
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/mindora_password_change_me/$(generate_password)/" "$env_file"
            sed -i '' "s/redis_password_change_me/$(generate_password)/" "$env_file"
            sed -i '' "s/minioadmin_password_change_me/$(generate_password)/" "$env_file"
            sed -i '' "s/rabbitmq_password_change_me/$(generate_password)/" "$env_file"
            sed -i '' "s/elastic_password_change_me/$(generate_password)/" "$env_file"
            sed -i '' "s/grafana_password_change_me/$(generate_password)/" "$env_file"
        else
            # Linux
            sed -i "s/mindora_password_change_me/$(generate_password)/" "$env_file"
            sed -i "s/redis_password_change_me/$(generate_password)/" "$env_file"
            sed -i "s/minioadmin_password_change_me/$(generate_password)/" "$env_file"
            sed -i "s/rabbitmq_password_change_me/$(generate_password)/" "$env_file"
            sed -i "s/elastic_password_change_me/$(generate_password)/" "$env_file"
            sed -i "s/grafana_password_change_me/$(generate_password)/" "$env_file"
        fi
        
        log_success "安全密钥生成完成"
    else
        log_info "密钥已设置，跳过生成"
    fi
}

# 验证配置
validate_configuration() {
    log_info "验证Docker Compose配置..."
    
    cd "./infrastructure/docker"
    
    # 验证开发环境配置
    if docker compose -f docker-compose.dev.yml config --quiet; then
        log_success "开发环境配置验证通过"
    else
        log_error "开发环境配置验证失败"
        exit 1
    fi
    
    # 验证测试环境配置
    if docker compose -f docker-compose.test.yml config --quiet; then
        log_success "测试环境配置验证通过"
    else
        log_error "测试环境配置验证失败"
        exit 1
    fi
    
    # 验证生产环境配置
    if docker compose -f docker-compose.prod.yml config --quiet; then
        log_success "生产环境配置验证通过"
    else
        log_error "生产环境配置验证失败"
        exit 1
    fi
    
    cd - > /dev/null
}

# 显示使用说明
show_usage() {
    log_info "Mindora SDK 基础设施初始化完成！"
    echo
    echo "📋 接下来的步骤:"
    echo "  1. 检查并修改环境配置: ./infrastructure/docker/.env"
    echo "  2. 启动开发环境: just infra-up"
    echo "  3. 查看服务状态: just infra-status"
    echo "  4. 访问监控界面: http://localhost:3000 (Grafana)"
    echo
    echo "🔧 常用命令:"
    echo "  just infra-up          # 启动基础设施"
    echo "  just infra-down        # 停止基础设施"
    echo "  just infra-logs        # 查看日志"
    echo "  just infra-restart     # 重启服务"
    echo
    echo "📊 服务访问地址:"
    echo "  Grafana:      http://localhost:3000"
    echo "  Prometheus:   http://localhost:9090"
    echo "  Kibana:       http://localhost:5601"
    echo "  Consul:       http://localhost:8500"
    echo "  MinIO:        http://localhost:9001"
    echo "  RabbitMQ:     http://localhost:15672"
    echo
    echo "🔐 默认登录信息请查看: ./infrastructure/docker/.env"
}

# 主函数
main() {
    echo "🏗️  Mindora SDK 基础设施环境初始化"
    echo "===================================="
    echo
    
    # 检查是否在项目根目录
    if [ ! -f "pyproject.toml" ] || [ ! -d "infrastructure" ]; then
        log_error "请在项目根目录下运行此脚本"
        exit 1
    fi
    
    # 执行初始化步骤
    check_requirements
    create_data_directories
    setup_environment
    generate_secrets
    validate_configuration
    show_usage
    
    log_success "Mindora SDK 基础设施初始化完成！"
}

# 如果脚本被直接执行，则运行主函数
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi