from google.cloud import firestore
import warnings
import json

# Suppress UserWarning from firestore
warnings.filterwarnings("ignore", category=UserWarning)

def delete_keys(task_id, email):
    # Set up Firestore client with credentials from environment variable
    db = firestore.Client()
    try:
        # Reference to the Firestore collection
        collection_ref = db.collection('Tasks')

        # Query documents in the collection where email + task_id matches
        docs = collection_ref.where('email', '==', email).limit(1).where('task_id', '==', task_id).get()

        # Check if any document is found
        if docs:
            # Iterate over the documents (should be only one because of limit(1))
            for doc in docs:
                # Delete the document
                doc.reference.delete()
            return json.dumps({"success": "Keys deleted successfully"}), 200
        else:
            return json.dumps({"error": "Invalid User/Task ID."}), 404

    except Exception as e:
        return json.dumps({"error": str(e)}), 500
