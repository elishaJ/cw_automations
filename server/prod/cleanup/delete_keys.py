from google.cloud import firestore
import warnings
from dotenv import load_dotenv

# Suppress UserWarning from firestore
warnings.filterwarnings("ignore", category=UserWarning)

def delete_task(task_id):
    db_error=None
    try:
        load_dotenv() 
        # Set up Firestore client with credentials from environment variable
        db = firestore.Client()

        # Reference to the Firestore collection
        collection_ref = db.collection('Tasks')

        # Query documents in the collection where email + task_id matches
        docs = collection_ref.where('task_id', '==', task_id).get()

        # Delete the document
        for doc in docs:
            doc.reference.delete()

        return db_error

    except Exception as e:
        db_error=str(e)
        return db_error