import os
import time
import boto3
import logging

from botocore.config import Config
from typing import Optional
from .defaults import LOGGER_NAME

logger = logging.getLogger(LOGGER_NAME)

def aws_region() -> str:
    """Get the AWS region"""
    return  os.environ.get("AWS_REGION", None) or os.environ.get("AWS_DEFAULT_REGION", "us-east-1")


def client_with_endpoint(
    endpoint: str,
) -> boto3.client:
    """Create a boto3 client for the zonal endpoint"""
    session = boto3.session.Session()
    config = Config(connect_timeout=300, read_timeout=300)
    return session.client(
        service_name="s3", 
        config=config,
        endpoint_url=f"https://{endpoint}",
    )


def client_with_zonal_endpoint(
    region_name: str,
    zone_id: str
) -> boto3.client:
    zonal_endpoint = f"s3express-{zone_id}.{region_name}.amazonaws.com"
    return client_with_endpoint(zonal_endpoint)


def s3_client(bucket: str, region_name: Optional[str] = None) -> boto3.client:
    """Create a boto3 client for S3"""
    is_expression_bucket = bucket.endswith("--x-s3")
    region_name = region_name or aws_region()

    if is_expression_bucket:
        zone_id = bucket.split('--')[-2]
        client = client_with_zonal_endpoint(region_name, zone_id)
        # add this line to speed it up
        client.create_session(Bucket=bucket)
        return client
    else:
        return boto3.client(
            "s3",
            region_name=region_name,
        )


def list_directory_buckets() -> list[str]:
    """List all buckets in the current account"""
    s3 = boto3.client("s3")
    response = s3.list_directory_buckets()
    return [bucket["Name"] for bucket in response["Buckets"]]


def list_bucket_objects(
    bucket: str, 
    region_name: str = None
) -> list[str]:
    """List all objects in a given bucket"""
    client = s3_client(bucket, region_name)
    return client.list_objects_v2(Bucket=bucket)["Contents"]


def get_bucket_object(
    bucket: str,
    key: str,
    _range: Optional[tuple[int, int]] = None,
) -> bytes:
    """Get a single object from a given bucket"""
    logger.info(f"Getting object {key} from bucket {bucket}")
    client = s3_client(bucket)

    # initiate timer
    start_time = time.time()
    response = client.get_object(Bucket=bucket, Key=key)
    logger.info(f"get_object took {time.time() - start_time} seconds")
    return response["Body"].read()