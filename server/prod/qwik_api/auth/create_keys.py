from google.cloud import firestore
from requests.exceptions import RequestException
from dotenv import load_dotenv

def export_keys(key_ids, email, server_ids):
    # Load environment variables from .env file
    load_dotenv() 
    # Set up Firestore client
    db = firestore.Client()
    try:
        # Reference to the Firestore collection
        collection_ref = db.collection('Tasks')

        # Add a new document to the collection and let Firestore auto-generate the document ID
        new_doc_ref = collection_ref.document()

        # Get the auto-generated document ID
        task_id = new_doc_ref.id

        # Store keys and other data in the document
        data = {
            'email': email,
            'task_id': task_id,
            'server_id': server_ids,
            'key_id': key_ids,
        }

        # Set the document data
        new_doc_ref.set(data)

        # Return the generated task_id
        return task_id

    except RequestException as e:
        print(f"Error storing data in Firestore: {e}")
        return None
