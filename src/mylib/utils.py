import logging
import os
from logging.config import dictConfig
from inspect import currentframe

def setup_logger(name=None, enable_file_logging=False, log_file="dump.log"):
    if name is None:
        # Auto-detect the calling module's name with a fallback to "root"
        frame = currentframe()
        name = "root"
        if frame and frame.f_back:
            name = frame.f_back.f_globals.get("__name__", "root")

    log_level = os.getenv("LOG_LEVEL", "INFO").upper()

    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "minimal": {"format": "%(message)s"},
            "detailed": {
                "format": "%(levelname)s %(asctime)s [%(name)s:%(filename)s:%(funcName)s:%(lineno)d]\n%(message)s\n"
            },
        },
        "handlers": {
            "console": {
                "class": "rich.logging.RichHandler",
                "formatter": "minimal",
                "level": log_level,
                "markup": True,
            },
        },
        "loggers": {
            "": {  # Root logger
                "handlers": ["console"],
                "level": log_level,
                "propagate": True,
            },
        },
    }

    if enable_file_logging:
        logging_config["handlers"]["file"] = {
            "class": "logging.handlers.RotatingFileHandler",
            "formatter": "detailed",
            "filename": log_file,
            "maxBytes": 5 * 1024 * 1024,  # 5 MB
            "backupCount": 3,
            "level": log_level,
        }
        logging_config["loggers"][""]["handlers"].append("file")

    dictConfig(logging_config)
    return logging.getLogger(name)
