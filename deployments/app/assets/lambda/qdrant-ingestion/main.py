# This lambda expects a batch with messages from SQS. Those messages are events
# triggered from S3 after the creation of a new file in a givne S3 bucket
#
import json
import logging
import os

import boto3
from llama_index.core import Settings
from llama_index.core.ingestion import IngestionPipeline
from llama_index.core.node_parser import SentenceSplitter
from llama_index.embeddings.jinaai import JinaEmbedding
from llama_index.readers.s3 import S3Reader
from llama_index.vector_stores.qdrant import QdrantVectorStore
from qdrant_client import QdrantClient

from utils import get_parameter, extract_event, extract_path_component

logger = logging.getLogger('app.vector_ingestion')

DENSE_EMBED_MODEL_NAME = os.getenv("DENSE_EMBED_MODEL_NAME", "jina-embeddings-v3")
SPARSE_EMBED_MODEL_NAME = os.getenv("SPARSE_EMBED_MODEL_NAME", "Qdrant/bm42-all-minilm-l6-v2-attentions")
SQS_ACK_QUEUE_URL = os.getenv("SQS_ACK_QUEUE_URL")

# Sensitive values are stored in SSM Parameter Store
# Lambda must have permissions to access those parameters (and KMS key if also configured)
jina_api_ssm = os.getenv("JINA_API_SSM")
qdrant_api_ssm = os.getenv("QDRANT_API_SSM")
qdrant_url_ssm = os.getenv("QDRANT_URL_SSM")

jina_api_key = get_parameter(name=jina_api_ssm)
qdrant_api_key = get_parameter(name=qdrant_api_ssm)
qdrant_url = get_parameter(name=qdrant_url_ssm)

# Configuration
splitter_params = {
    "chunk_size": 500,
    "chunk_overlap": 50
}

embed_model = JinaEmbedding(
    api_key=jina_api_key,
    model=DENSE_EMBED_MODEL_NAME,
    dimensions=1024,
    late_chunking=False,
    embedding_type="float",
    task="retrieval.passage",
)

Settings.embed_model = embed_model
Settings.llm = None

qdrant = QdrantClient(url=qdrant_url, api_key=qdrant_api_key, timeout=None)
sqs = boto3.client('sqs')


def handler(event, context):
    messages = extract_event(event)
    total_messages = len(messages)

    response = {
        'statusCode': 200,
        'body': 'Success'
    }
    # In case of processing a batch of messages, there can be failures. Those will be appended to this list.
    batch_item_failures = []

    for ith, message in enumerate(messages, 1):
        receipt_handle = message["receipt_handle"]  # Use to acknowledge success at processing.
        message_id = message["message_id"]  # Use to notify failure at processing.
        s3_full_path = message["path"]  # Use for logging purposes

        try:
            bucket, key = message["bucket"], message["key"]
            # that will take the key and "find" the  right collection name.
            # The element should have a key with the format: `landing/<collection-name>/YYYY/MM/DD/file.pdf`
            collection_name = extract_path_component(key=key, depth=1)
            vector_store = QdrantVectorStore(
                client=qdrant,
                collection_name=collection_name,
                enable_hybrid=True,
                fastembed_sparse_model=SPARSE_EMBED_MODEL_NAME
            )

            logger.info("Loading content for %s/%s files", ith, total_messages)
            documents = S3Reader(bucket=bucket, key=key).load_data()
            pipeline = IngestionPipeline(
                transformations=[
                    SentenceSplitter(**splitter_params),
                    embed_model,
                ],
                vector_store=vector_store
            )
            nodes = pipeline.run(documents=documents)
        except Exception as e:
            batch_item_failures.append({"itemIdentifier": message_id})
            logger.error("Message '%s' has failed during batch processing file %s because %s.",
                         message_id, s3_full_path, repr(e))
        else:
            logger.info("Message '%s' for file %s successfully processed", message_id, s3_full_path)
            sqs.delete_message(QueueUrl=SQS_ACK_QUEUE_URL, ReceiptHandle=receipt_handle)
            logger.info("Message '%s' successfully acknowledged", message_id)

        # Handle failed items: if any failure, inform what element failed and change body message accordingly
        # Case: Partial Success, if at least 1 failure; Failure if 100% failure.
        response["batchItemFailures"] = batch_item_failures
        if (len(batch_item_failures) > 0) and (len(batch_item_failures) < total_messages):
            response["body"] = "Partial Success"
        elif len(batch_item_failures) == total_messages:
            response["body"] = "Failure"

        response["batchItemFailures"] = batch_item_failures
        return json.dumps(response)
