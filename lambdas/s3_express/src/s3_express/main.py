import os
import json
import logging

from .about import __version__, __version_released__
from .helpers import configure_lambda_logger
from .bucket_ops import list_bucket_objects, get_bucket_object
from .defaults import LOGGER_NAME

# load outside handler 
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")

logger = logging.getLogger(LOGGER_NAME)
if not logger.handlers:
    configure_lambda_logger(LOGGER_NAME, loglevel=os.environ.get("LOGLEVEL", None))

def handler(event: dict, context: object):
    """
    Main function called by AWS lambda
    Args:
        event (dict): Event data that's passed to the function upon execution.
        context (object): Context object passed to the handler.
            This object provides methods and properties that provide information about the invocation,
            function, and execution environment.
    Raises:
        Exception: exceptions caught by the handler
    """
    try:
        logger.info(f"Lambda function triggered with payload: {event}")

        bucket = event.get("bucket", None)
        key = event.get("key", None)

        if bucket is None or key is None:
            logger.error("Bucket or key not provided")
            return 1

        bucket_keys = list_bucket_objects(bucket=bucket)
        logger.info(f"Bucket keys found: {bucket_keys}")

        object_bytes = get_bucket_object(bucket=bucket, key=key)
        logger.info(f"Object loaded with size: {len(object_bytes)} bytes")
    except ImportError as error:
        error_message = f"ImportError caught in handler: {error}"
        logger.error(error_message, exc_info=True)

    except KeyError as error:
        error_message = f"KeyError caught in handler: key {error} not found"
        logger.error(error_message, exc_info=True)

    except Exception as error:
        error_message = f"Exception caught in handler: {error}"
        logger.error(error_message, exc_info=True)


def cli(args: list[str] = []) -> int:
    """Main function called via CLI"""
    try:
        payload = json.loads(args[0])
    except IndexError:
        raise SystemExit(f'Usage: {__name__.split(".")[0]} <payload>')

    logger.info(f"CLI triggered with payload: {payload}")
    return handler(payload, None)
