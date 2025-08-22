import json
import redis
import os

def handler(event, context):
    try:
        r = redis.Redis(
            host="192.168.100.162",
            port=int(os.getenv("REDIS_PORT", 6379)),
            decode_responses=True
        )

        # 1. Cadastrar a key
        r.set("myKey", "Hello from Lambda & Redis")

        # 2. Recuperar a key
        value = r.get("myKey")

        return {
            "statusCode": 200,
            "body": json.dumps({"stored_value": value})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
