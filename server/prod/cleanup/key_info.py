from google.cloud import firestore
import warnings
from dotenv import load_dotenv

# Suppress UserWarning from firestore
warnings.filterwarnings("ignore", category=UserWarning)

def key_info(task_id):            # Load environment variables from .env file
    search_error = None
    
    load_dotenv()

    # Set up Firestore client with credentials from environment variable
    db = firestore.Client()

    # Reference to a Firestore collection
    collection_ref = db.collection('Tasks')

    # Query documents in the collection where task_id is 12345
    query = collection_ref.where('task_id', '==', task_id).limit(1)
    
    # Execute the query
    docs = query.get()

    # Initialize lists for key_ids and server_ids
    key_ids = []
    server_ids = []

    if not docs:
        search_error = "Task ID not found"
        return key_ids, server_ids, search_error

    # Iterate over the documents and append their keys and tasks
    for doc in docs:
        key_ids.extend(doc.to_dict().get('key_id'))
        server_ids.extend(doc.to_dict().get('server_id'))
    
    # Return flattened lists in the JSON response
    return key_ids, server_ids, search_error