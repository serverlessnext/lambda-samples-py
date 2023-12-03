import logging
from typing import Optional


def configure_lambda_logger(name: str, loglevel: Optional[str] = None) -> None:
    lambda_logger = logging.getLogger(name)

    if loglevel is not None:
        level = logging.getLevelName(loglevel)
        assert isinstance(level, int), f"Invalid log level: {loglevel}"
    else:
        level = logging.INFO

    lambda_logger.setLevel(level)

    # pass through to lambda root logger
    lambda_logger.propagate = True