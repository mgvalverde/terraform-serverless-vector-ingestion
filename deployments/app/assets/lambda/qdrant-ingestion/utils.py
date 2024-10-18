import json
import logging
import urllib.parse
from typing import Dict, Iterable, List, Any
from uuid import uuid5, UUID

import boto3

logger = logging.getLogger('lambda-utils')


def to_unicode(string, restore_space=True):
    """

    Args:
        string:
        restore_space:

    Returns:

    """
    decoded_string = urllib.parse.unquote(string)
    if restore_space:
        decoded_string = decoded_string.replace("+", " ")
    return decoded_string


def extract_event(event: Dict[str, Any], force_key_unicode: bool = True, ) -> List[Dict[str, str]]:
    """
    Given an event from S3 > SQS, it extracts the file names, providing a
    list whose elements have the format 's3://<bucket>/<key> together with the message id and receipt handle.
    The `message ID` is important in case of item processing failure
    The `receipt handle` is a temporary identifier that is provided each time a message is received from the queue.
     It is used to acknowledge the receipt of the message and to perform further actions on the message, such as
     deleting it or changing its visibility.
    """
    records = event["Records"]
    paths = []
    for record in records:
        message_id = record.get("messageId")
        receipt_handle = record.get("receiptHandle")
        if message_id is None:
            logger.warning("Problem retrieving 'messageId' from record")
        if receipt_handle is None:
            logger.warning("Problem retrieving 'receiptHandle' from record")

        try:
            subrecords = json.loads(record.get("body", ""))["Records"]
        except KeyError:
            logger.warning("No records found in the received message")
            subrecords = []

        # NOTE: subrecords is a list of messages, event if only 1 element is expected
        for payload in subrecords:
            s3_body = payload.get("s3", {})
            bucket = s3_body["bucket"]["name"]
            key = s3_body["object"]["key"]
            if force_key_unicode:
                key = to_unicode(key)
            paths.append(
                {
                    "message_id": message_id,
                    "receipt_handle": receipt_handle,
                    "bucket": bucket,
                    "key": key,
                    "path": f"s3://{bucket}/{key}"
                },
            )
    return paths


def extract_path_component(key: str, depth: int = 0):
    components = key.split("/")
    return components[depth]


def uuid_id_with_namespace(payload: Dict, namespace: UUID, fields: Iterable = None, parent_key: str = None) -> str:
    SEP = ""
    payload = payload[parent_key] if parent_key else payload

    def get_fields(fields):
        if fields is not None:
            _ = [payload[field] for field in fields]
            return SEP.join(_)
        else:
            return json.dumps(payload)

    name = get_fields(fields)
    return str(uuid5(namespace=namespace, name=name))


def get_parameters(path, recursive=True, next_token=None, client=None):
    ssm_client = client or boto3.client('ssm')
    parameters = {}
    request_params = {
        'Path': path,
        'Recursive': recursive,
        'WithDecryption': True
    }
    if next_token:
        request_params['NextToken'] = next_token
    response = ssm_client.get_parameters_by_path(**request_params)
    for param in response['Parameters']:
        key = param["Name"].replace(path, "").lstrip(r"/")
        parameters[key] = param["Value"]
    if 'NextToken' in response:
        parameters.update(get_parameters(path, recursive, response['NextToken']))
    return parameters

def get_parameter(name, version=None, client=None):
    ssm_client = client or boto3.client('ssm')
    kwargs = {
        'Name': f"{name}:{version}" if version else name,
        'WithDecryption': True
    }
    param = ssm_client.get_parameter(**kwargs)
    return param["Parameter"]["Value"]