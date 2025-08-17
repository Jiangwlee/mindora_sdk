-- Mindora SDK 数据库Schema初始化脚本
-- 为不同的应用创建独立的Schema，实现数据隔离

-- 创建应用专用Schema
CREATE SCHEMA IF NOT EXISTS mindora_core AUTHORIZATION mindora_user;
CREATE SCHEMA IF NOT EXISTS mindora_users AUTHORIZATION mindora_user;
CREATE SCHEMA IF NOT EXISTS mindora_files AUTHORIZATION mindora_user;
CREATE SCHEMA IF NOT EXISTS mindora_search AUTHORIZATION mindora_user;
CREATE SCHEMA IF NOT EXISTS mindora_tasks AUTHORIZATION mindora_user;
CREATE SCHEMA IF NOT EXISTS mindora_logs AUTHORIZATION mindora_user;

-- 创建监控和审计Schema
CREATE SCHEMA IF NOT EXISTS mindora_monitoring AUTHORIZATION mindora_user;
CREATE SCHEMA IF NOT EXISTS mindora_audit AUTHORIZATION mindora_user;

-- 设置搜索路径
ALTER USER mindora_user SET search_path TO mindora_core, mindora_users, mindora_files, mindora_search, mindora_tasks, public;

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" SCHEMA public;

-- 授权
GRANT ALL PRIVILEGES ON SCHEMA mindora_core TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_users TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_files TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_search TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_tasks TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_logs TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_monitoring TO mindora_user;
GRANT ALL PRIVILEGES ON SCHEMA mindora_audit TO mindora_user;

-- 授予在这些Schema中创建表的权限
GRANT CREATE ON SCHEMA mindora_core TO mindora_user;
GRANT CREATE ON SCHEMA mindora_users TO mindora_user;
GRANT CREATE ON SCHEMA mindora_files TO mindora_user;
GRANT CREATE ON SCHEMA mindora_search TO mindora_user;
GRANT CREATE ON SCHEMA mindora_tasks TO mindora_user;
GRANT CREATE ON SCHEMA mindora_logs TO mindora_user;
GRANT CREATE ON SCHEMA mindora_monitoring TO mindora_user;
GRANT CREATE ON SCHEMA mindora_audit TO mindora_user;