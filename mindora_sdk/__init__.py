"""
Mindora SDK - AI基础设施统一接口

提供数据库、存储、消息队列、搜索、配置管理等核心基础设施服务的统一SDK接口。
"""

from .core.sdk import MindoraSDK
from .core.exceptions import MindoraSDKError, ConfigurationError, ConnectionError

__version__ = "0.1.0"
__author__ = "Mindora Team"
__email__ = "team@mindora.ai"

__all__ = [
    "MindoraSDK",
    "MindoraSDKError",
    "ConfigurationError", 
    "ConnectionError"
]