"""
Mindora SDK 异常定义
"""


class MindoraSDKError(Exception):
    """SDK基础异常类"""
    pass


class ConfigurationError(MindoraSDKError):
    """配置错误异常"""
    pass


class ConnectionError(MindoraSDKError):
    """连接错误异常"""
    pass


class DatabaseError(MindoraSDKError):
    """数据库操作异常"""
    pass


class FileStorageError(MindoraSDKError):
    """文件存储异常"""
    pass


class MessageQueueError(MindoraSDKError):
    """消息队列异常"""
    pass


class SearchError(MindoraSDKError):
    """搜索服务异常"""
    pass


class ServiceDiscoveryError(MindoraSDKError):
    """服务发现异常"""
    pass