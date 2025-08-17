-- Mindora SDK 初始数据
-- 创建基础数据和配置表

-- 设置工作Schema
SET search_path TO mindora_core, public;

-- 创建系统配置表
CREATE TABLE IF NOT EXISTS system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(255) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建应用注册表
CREATE TABLE IF NOT EXISTS applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    schema_name VARCHAR(63) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    config JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建服务健康检查表
CREATE TABLE IF NOT EXISTS service_health (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL, -- 'healthy', 'unhealthy', 'unknown'
    last_check TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_time_ms INTEGER,
    error_message TEXT,
    metadata JSONB DEFAULT '{}'
);

-- 插入初始系统配置
INSERT INTO system_config (key, value, description) VALUES
('system.version', '"1.0.0"', 'Mindora SDK版本'),
('system.environment', '"development"', '当前环境'),
('database.max_connections', '100', '数据库最大连接数'),
('redis.default_ttl', '3600', 'Redis默认TTL（秒）'),
('minio.default_bucket', '"mindora-default"', '默认对象存储桶'),
('search.default_index', '"mindora-documents"', '默认搜索索引'),
('monitoring.enabled', 'true', '是否启用监控'),
('logging.level', '"INFO"', '日志级别'),
('backup.enabled', 'true', '是否启用自动备份'),
('security.encryption_enabled', 'true', '是否启用数据加密')
ON CONFLICT (key) DO NOTHING;

-- 注册核心应用
INSERT INTO applications (name, display_name, description, schema_name) VALUES
('core', 'Mindora Core', 'Mindora SDK核心服务', 'mindora_core'),
('users', 'User Service', '用户管理服务', 'mindora_users'),
('files', 'File Service', '文件管理服务', 'mindora_files'),
('search', 'Search Service', '搜索服务', 'mindora_search'),
('tasks', 'Task Service', '任务管理服务', 'mindora_tasks')
ON CONFLICT (name) DO NOTHING;

-- 初始化服务健康状态
INSERT INTO service_health (service_name, status, metadata) VALUES
('postgres', 'healthy', '{"version": "16.4"}'),
('redis', 'unknown', '{"version": "7.4"}'),
('minio', 'unknown', '{"version": "RELEASE.2025-07-23T15-54-02Z"}'),
('rabbitmq', 'unknown', '{"version": "4.1"}'),
('elasticsearch', 'unknown', '{"version": "8.19.2"}'),
('qdrant', 'unknown', '{"version": "1.15.3"}'),
('consul', 'unknown', '{"version": "1.19"}'),
('prometheus', 'unknown', '{"version": "3.5.0"}'),
('grafana', 'unknown', '{"version": "11.3.0"}')
ON CONFLICT DO NOTHING;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_system_config_key ON system_config(key);
CREATE INDEX IF NOT EXISTS idx_applications_name ON applications(name);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_service_health_service ON service_health(service_name);
CREATE INDEX IF NOT EXISTS idx_service_health_status ON service_health(status);
CREATE INDEX IF NOT EXISTS idx_service_health_check_time ON service_health(last_check);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表添加更新时间触发器
CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON system_config 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();