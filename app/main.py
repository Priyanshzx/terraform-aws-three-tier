import os
import uuid
from datetime import datetime, timezone
from functools import lru_cache
from typing import Literal

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Task Tracker API")

Status = Literal["todo", "in_progress", "done"]


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)


class TaskUpdate(BaseModel):
    status: Status


@lru_cache
def get_table():
    dynamodb = boto3.resource(
        "dynamodb", region_name=os.environ.get("AWS_REGION", "ap-south-1")
    )
    return dynamodb.Table(os.environ["TABLE_NAME"])


def _is_missing(error: ClientError) -> bool:
    return error.response["Error"]["Code"] == "ConditionalCheckFailedException"


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/tasks", status_code=201)
def create_task(body: TaskCreate):
    item = {
        "task_id": str(uuid.uuid4()),
        "title": body.title,
        "status": "todo",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    get_table().put_item(Item=item)
    return item


@app.get("/tasks")
def list_tasks():
    items = get_table().scan().get("Items", [])
    return {"count": len(items), "tasks": items}


@app.get("/tasks/{task_id}")
def get_task(task_id: str):
    item = get_table().get_item(Key={"task_id": task_id}).get("Item")
    if not item:
        raise HTTPException(status_code=404, detail="Task not found")
    return item


@app.put("/tasks/{task_id}")
def update_task(task_id: str, body: TaskUpdate):
    try:
        response = get_table().update_item(
            Key={"task_id": task_id},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": body.status},
            ConditionExpression="attribute_exists(task_id)",
            ReturnValues="ALL_NEW",
        )
    except ClientError as error:
        if _is_missing(error):
            raise HTTPException(status_code=404, detail="Task not found")
        raise
    return response["Attributes"]


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(task_id: str):
    try:
        get_table().delete_item(
            Key={"task_id": task_id},
            ConditionExpression="attribute_exists(task_id)",
        )
    except ClientError as error:
        if _is_missing(error):
            raise HTTPException(status_code=404, detail="Task not found")
        raise
