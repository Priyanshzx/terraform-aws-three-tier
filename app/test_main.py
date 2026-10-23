from unittest.mock import MagicMock

import pytest
from botocore.exceptions import ClientError
from fastapi.testclient import TestClient

import main


@pytest.fixture
def table(monkeypatch):
    fake = MagicMock()
    monkeypatch.setattr(main, "get_table", lambda: fake)
    return fake


@pytest.fixture
def client():
    return TestClient(main.app)


def _conditional_failure():
    return ClientError(
        {"Error": {"Code": "ConditionalCheckFailedException", "Message": "missing"}},
        "UpdateItem",
    )


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_task(client, table):
    response = client.post("/tasks", json={"title": "Write docs"})
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Write docs"
    assert body["status"] == "todo"
    table.put_item.assert_called_once()


def test_create_task_rejects_empty_title(client, table):
    response = client.post("/tasks", json={"title": ""})
    assert response.status_code == 422
    table.put_item.assert_not_called()


def test_list_tasks(client, table):
    table.scan.return_value = {"Items": [{"task_id": "1", "title": "a", "status": "todo"}]}
    response = client.get("/tasks")
    assert response.status_code == 200
    assert response.json()["count"] == 1


def test_get_task_found(client, table):
    table.get_item.return_value = {"Item": {"task_id": "1", "title": "a", "status": "todo"}}
    response = client.get("/tasks/1")
    assert response.status_code == 200
    assert response.json()["task_id"] == "1"


def test_get_task_not_found(client, table):
    table.get_item.return_value = {}
    response = client.get("/tasks/missing")
    assert response.status_code == 404


def test_update_task(client, table):
    table.update_item.return_value = {"Attributes": {"task_id": "1", "status": "done"}}
    response = client.put("/tasks/1", json={"status": "done"})
    assert response.status_code == 200
    assert response.json()["status"] == "done"


def test_update_task_not_found(client, table):
    table.update_item.side_effect = _conditional_failure()
    response = client.put("/tasks/missing", json={"status": "done"})
    assert response.status_code == 404


def test_update_task_rejects_bad_status(client, table):
    response = client.put("/tasks/1", json={"status": "finished"})
    assert response.status_code == 422


def test_delete_task_not_found(client, table):
    table.delete_item.side_effect = _conditional_failure()
    response = client.delete("/tasks/missing")
    assert response.status_code == 404


def test_delete_task(client, table):
    response = client.delete("/tasks/1")
    assert response.status_code == 204
