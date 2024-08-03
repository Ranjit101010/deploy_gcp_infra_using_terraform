from google.cloud import storage
from google.cloud import bigquery
import functions_framework
# from constants_gcs_to_bq import constants_gcs_to_bq

@functions_framework.cloud_event
def gcs_to_bq(cloud_event):
    """_summary_

    Args:
        cloud_event (_type_): _description_

    Returns:
        _type_: _description_
    """
    # const_obj              = constants_gcs_to_bq()
    data                   = cloud_event.data
    event_type             = cloud_event["type"]
    bucket_name, blob_name = get_gcs_bucket(bucket_name = data["bucket"],
                                            blob_name   = data["name"],
                                            project_id  = 'event-trigger-cloud-storage')
    if bucket_name is not None and blob_name is not None:
        print(f"bucket name: '{bucket_name}' and blob name: '{blob_name}' exists..")
        uri                    = f'gs://{bucket_name}/{blob_name}'
        is_data_loaded         = load_data_from_gcs_to_bq(dataset_name  = 'orders_stg_dataset',
                                                        table_name = 'orders_stg_table',
                                                        bucket_uri = uri,
                                                        project_id = 'event-trigger-cloud-storage')
        if (is_data_loaded):
        # job = bigquery.QueryJob(
        #     job_id = final_job.job_id,
        #     client = bq_client,
        #     query  = const_obj.query
        # )
        # query_result = bq_client.query(const_obj.query)
        # for row in query_result.result():
        #     print(row[0])
            is_update_schema = update_table_with_new_schema_fields(dataset_name   = 'orders_stg_dataset',
                                                                    table_name    = 'orders_stg_table',
                                                                    project_id    = 'event-trigger-cloud-storage',
                                                                    schema_fields = [('source_timestamp', 'TIMESTAMP'),
                                                                                        ('source_type', 'STRING')])
            if (is_update_schema):

                is_blob_moved = move_blobs_from_source_to_destination(
                                    source_bucket      = 'bucket-gcs-to-bq-d',
                                    destination_bucket = 'bucket-gcs-to-bq-archival-d',
                                    blob_name          =  blob_name,
                                    project_id         = 'event-trigger-cloud-storage'
                                )
                if (is_blob_moved):
                    print(f"Whole Cloud Storage Event trigger process has been done..")
                else:
                    print(f"Whole Cloud Storage Event trigger process is still pending....")
            else:
                pass
            print("data is ingested successfully")
            return 'data is ingested successfully'
        else:
            print("data is not ingested successfully")
            return 'data is not ingested successfully'
    else:
        return f' "{bucket_name}" bucket name \n and \n "{blob_name}" blob name does not exists'



def get_gcs_bucket(bucket_name: str, blob_name: str, project_id: str) -> tuple[str, str] | tuple[None, None]:
    """_summary_

    Args:
        bucket_name (str): _description_
        blob_name (str): _description_
        project_id (str): _description_

    Returns:
        tuple[str, str] | tuple[None, None]: _description_
    """

    try:
        gcs_client  = storage.Client(project = project_id)
        gcs_bucket  = gcs_client.get_bucket(bucket_name)
        bucket_name = gcs_bucket.name
        blob        = gcs_bucket.get_blob(blob_name)
        blob_name   = blob.name
        return bucket_name, blob_name
    except Exception as e:
        print(f"Error occurred: {e} ")
        return None, None

def move_blobs_from_source_to_destination(source_bucket: str, destination_bucket: str, blob_name: str, project_id: str) -> bool:
    """_summary_

    Args:
        source_bucket (str): _description_
        destination_bucket (str): _description_
        blob_name (str): _description_
        project_id (str): _description_

    Returns:
        bool: _description_
    """
    try:
        storage_client          = storage.Client(project = project_id)
        source_bucket           = storage_client.bucket(source_bucket)
        dest_bucket             = storage_client.bucket(destination_bucket)
        source_bucket_name      = source_bucket.name
        destination_bucket_name = dest_bucket.name
        blob                    = source_bucket.get_blob(blob_name)
        blob_copy               = source_bucket.copy_blob(blob, dest_bucket)
        print(
            "Blob {} in bucket {} copied to blob {} in bucket {}.".format(
                blob.name,
                source_bucket.name,
                blob_copy.name,
                dest_bucket.name,
            )
        )
        source_bucket.delete_blob(blob_name)
        print(
            f"{blob_name} is deleted successfully and moved to archive bucket successfully"
        )
        return True
    except Exception as e:
        print(f"Error occurred: {e}")
        return False


def update_table_with_new_schema_fields(dataset_name: str, table_name: str, project_id: str, schema_fields: list[tuple]) -> bool:
    """_summary_

    Args:
        dataset_name (str): _description_
        table_name (str): _description_
        project_id (str): _description_
        schema_fields (list[tuple]): _description_

    Returns:
        bool: _description_
    """
    try:
        client          = bigquery.Client(project = project_id)
        new_schema      = []
        for fields in schema_fields:
            new_schema.append(bigquery.SchemaField(fields[0], fields[1]))    
        table_ref_obj    = client.dataset(dataset_name).table(table_name)
        table_ref        = client.get_table(table_ref_obj)
        existing_schema  = table_ref.schema
        updated_schema   = existing_schema + new_schema
        table_ref.schema = updated_schema
        client.update_table(table_ref, ['schema'])
        print(f"Updated Schema : {table_ref.schema}")
        print(f"New schema updated successfully in {table_ref.table_id}")
        fully_qualified_table  = str(table_ref.full_table_id).replace(':', '.')
        job_config             = bigquery.QueryJobConfig()
        query                  = f'''UPDATE `{fully_qualified_table}` SET source_timestamp = CURRENT_TIMESTAMP(),
                                    source_type = "sustainability" WHERE TRUE '''
        # job_config.destination = table_ref_obj
        query_job              = client.query(query = query,
                                                job_config = job_config)
        query_job.result()
        print(f"The column values have been updated with current timestamp and sustainability successfully ")
        return True
    except Exception as e:
        print(f"Error occurred: {e}")
        print(f"New schema not updated successfully in {table_ref.table_id}")
        return False

def load_data_from_gcs_to_bq(dataset_name: str, table_name: str, bucket_uri: str, project_id: str) -> tuple[str, bool]:
    """_summary_

    Args:
        dataset_name (str): _description_
        table_name (str): _description_
        bucket_uri (str): _description_
        project_id (str): _description_

    Returns:
        tuple[str, bool]: _description_
    """
    try:
        bq_client = bigquery.Client(project = project_id)
        # stg_table = bq_client.create_table(const_obj.stg_table,
        #                                     exists_ok = True)
        job       = bigquery.LoadJobConfig(write_disposition = "WRITE_TRUNCATE",
                                            autodetect = True,
                                            source_format = "NEWLINE_DELIMITED_JSON")
        # WRITE_TRUNCATE: If the table already exists, BigQuery overwrites the data, removes the constraints and uses the schema from the load job.
        # WRITE_APPEND: If the table already exists, BigQuery appends the data to the table.
        # WRITE_EMPTY: If the table already exists and contains data, a 'duplicate' error is returned in the job result.
        table_name = f"{project_id}.{dataset_name}.{table_name}"
        final_job = bq_client.load_table_from_uri(source_uris   = bucket_uri,
                                                    destination = table_name,
                                                    job_config  = job)
        final_job.result()
        print('data is ingested successfully')
        return  True

    except Exception as e:
        print(f"Error occurred: {e}")
        print('data is not ingested successfully')
        return  False



