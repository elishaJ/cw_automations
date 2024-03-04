# import functions_framework
import requests
import warnings
from google.cloud import firestore
from flask import Flask, jsonify, request
from delete_keys import delete_task
from key_info import key_info

# Suppress UserWarning from firestore
warnings.filterwarnings("ignore", category=UserWarning)

app = Flask(__name__)
BASE_URL = "https://api.cloudways.com/api/v1"
EZ_API = 'https://us-central1-cw-automations.cloudfunctions.net'

def get_params(request):
    task_id = request.args.get('task_id')
    
    # Check if the request contains JSON data
    if (not task_id) and request.content_type == 'application/json':
        data = request.json
        if data:
            #email = email or data.get('email')
            task_id = task_id or data.get('task_id')
    
    elif (not task_id) and request.content_type == 'application/x-www-form-urlencoded':
        task_id =  request.form.get('task_id')
    return task_id

# Function to get Oauth access token from Authorization header
def extract_access_token(request):
    auth_header = request.headers.get('Authorization')
    if auth_header:
        token_type, token = auth_header.split(' ', 1)
        if token_type.lower() == 'bearer':
            return token.strip()
    return None

# Verify access token
def verify_access_token(access_token):
    error = None
    #server_ids = None
    headers = {"Authorization": "Bearer " + access_token}
    response = requests.get(EZ_API + '/servers/ids', headers=headers)
    if response.status_code != 200:
        error = response.text
        return error
    else:
        return error

def delete_ssh_key(access_token, server_ids, key_ids):
    error = None
    for i in range(len(key_ids)):
        headers = {"Authorization": "Bearer " + access_token}
        response = requests.delete(
            f"{BASE_URL}/ssh_key/{key_ids[i]}?server_id={server_ids[i]}",
            headers=headers
        )
        if response.status_code != 200:
            error = response.text
            return error
    return error

@app.route('/cleanup', methods=['DELETE'])
def main():  
    if request.method == 'DELETE':   
        task_id = get_params(request)  # Adjusted to retrieve only task_id
    
        if not task_id:
            return jsonify({"error": "Invalid request. Task ID is required"}), 400

        # Fetch access token from request
        access_token = extract_access_token(request)
        if not access_token:
            return jsonify({"error": "Access token is required"}), 400
    
        
        token_error = verify_access_token(access_token)
        if token_error:
            return token_error, 400
        else:
            key_ids, server_ids, search_error = key_info(task_id)
            if search_error: 
                return jsonify({"error": search_error}), 404 
            
            deletion_error = delete_ssh_key(access_token, server_ids, key_ids)
            if not deletion_error: 
                db_error = delete_task(task_id)
                if not db_error:
                    return jsonify({"success": "Keys deleted successfully"}), 200
                else:
                    return jsonify({"error": db_error}), 500

            else:
                return deletion_error, 401
            
    else:
        return jsonify({"error": "Invalid route/request method"}), 404

if __name__ == "__main__":
    app.run(debug=True)