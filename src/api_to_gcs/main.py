''' importing the required packages in this python file'''

import json
import datetime
import requests
from google.cloud import storage


def api_to_gcs(requests):
    
    '''
    '''

    response = requests.get(
        "http://127.0.0.1:8000",
        timeout = 100).json()
    total_count = len(response)
    print(response[0:1])
    print(f'the total length of the response:{total_count}')
    print(type(response))
    storage_client = storage.Client(project = "ranjit-1610110")
    bucket = storage_client.get_bucket("bucket-gcs-to-bq-d")
    print(f'bucket:{bucket} has been successfully created')

    INITIAL_LOAD = 0
    FINAL_LOAD = 100
    while total_count > 0:
        print("start of the iteration")
        blob = bucket.blob(f"incoming/{datetime.datetime.today()}.json")
        print(f"{blob} the blob has been successfully created")
        with blob.open('w') as f:
            json.dump(response[INITIAL_LOAD:FINAL_LOAD],f)
        print(f'the json file has been successflly loaded to the {blob}')
        print("end of the iteration")
        INITIAL_LOAD = INITIAL_LOAD + 100
        FINAL_LOAD = FINAL_LOAD + 100
        total_count = total_count - 100

    return response
