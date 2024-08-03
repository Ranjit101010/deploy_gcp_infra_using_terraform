import requests
import json

event_data = {
    "id"  : "123457678",
    "type": "google.cloud.storage.object.v1.finalized",
    "data": {
        "bucket": "bucket-gcs-to-bq-d",
        "name": "incoming/part-r-00000-990f5773-9005-49ba-b670-631286032674"
    }
}

headers = {
    'Content-Type': 'application/json',
    'Ce-Id': event_data['id'],
    'Ce-Type': event_data['type'],
    'Ce-specversion': '1.0',
    'Ce-Source': 'local-event'
}

response = requests.post(r"http://localhost:8080/", data = json.dumps(event_data), headers = headers)
print(response.status_code)
print(response.text)