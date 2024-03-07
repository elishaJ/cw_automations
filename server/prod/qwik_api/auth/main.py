import functions_framework
import requests
from create_keys import export_keys

from time import sleep
from flask import Flask, jsonify, request

app = Flask(__name__)
BASE_URL = "https://api.cloudways.com/api/v1"
EZ_API = 'https://us-central1-cw-automations.cloudfunctions.net'

def get_params(request):
    server_id = request.form.get('server_id') 
    project_id = request.form.get('project_id')
    pub_key = request.form.get('pub_key')
    email = request.form.get('email')
    # Check if the request contains JSON data
    if (not server_id or not project_id) and request.content_type == 'application/json':
        data = request.json
        if data:
            server_id = server_id or data.get('server_id')
            project_id = project_id or data.get('project_id')
            pub_key = pub_key or data.get('pub_key')
            email = email or data.get('email')

    return server_id, project_id, pub_key, email

# Function to get Oauth access token from Authorization header
def extract_access_token(request):
    auth_header = request.headers.get('Authorization')
    if auth_header:
        token_type, token = auth_header.split(' ', 1)
        if token_type.lower() == 'bearer':
            return token.strip()
    return None

# No project/server_id provided. Get all running server IDs
def get_server_ids(access_token):
    error = None
    server_ids = None
    headers = {"Authorization": "Bearer " + access_token}
    response = requests.get(EZ_API + '/servers/ids', headers=headers)
    if response.status_code != 200:
        error = response.text
        return server_ids, error
    else:
        server_ids = response.json().get('id', [])
        return server_ids, error

def get_server_ids_by_project(access_token, project_id):
    error = None
    project_server_ids = None
    headers = {"Authorization": "Bearer " + access_token}
    params = {"project_id": project_id}
    response = requests.get(EZ_API + '/apps', headers=headers, params=params)
    if response.status_code != 200:
        error = response.text
        return project_server_ids, error
    else:
        # server_ids = response.json().get('apps[server_id]', [])
        server_ids = [app['server_id'] for app in response.json().get('apps', [])]
        project_server_ids = set(server_ids)
        return project_server_ids, error

# Function to check if provided server ID  exists
def verify_server_id(access_token, server_id):
    server_exists = 0
    error = None
    headers = {"Authorization": "Bearer " + access_token}
    response = requests.get(EZ_API + '/servers/ids', headers=headers)
    if response.status_code != 200:
        error = response.text
        return server_exists, error
    else:
        #server_ids = response.json().get('id', [])
        if server_id in response.json().get("id", []):
            server_exists = 1
            return server_exists, error
        else:
            error = {"error": "Server ID is invalid"}
            return server_exists, error
    
def create_ssh_keys_on_servers(access_token, server_ids, pub_key):
    key_ids = []
    error = None 
    for id in server_ids:
        data = {
            "server_id": id,
            "ssh_key_name": "Bulkatron D10",
            "ssh_key": pub_key
        }
        response = requests.post(BASE_URL + '/ssh_key', headers={"Authorization": "Bearer " + access_token}, json=data)
        if response.status_code != 200:
            error = response.text
            return key_ids, error
        else: 
            key_id = response.json().get('id')
            key_ids.append(key_id)
            sleep(5)
    return key_ids, error

@app.route('/auth', methods=['POST'])
def main():  
    if request.method == 'POST':   
        server_id, project_id, pub_key, email = get_params(request)

        if not pub_key:
            return jsonify({"error": "Invalid request. SSH public key is required"}), 400
        
        if not email:
            return jsonify({"error": "Invalid request. Email is required"}), 400

        # Fetch access token from request
        access_token = extract_access_token(request)
        if not access_token:
            return jsonify({"error": "Access token is required"}), 400
        
        # If project ID is provided
        elif project_id:
            project_server_ids, project_ids_error = get_server_ids_by_project(access_token, project_id)
            if not project_server_ids and not project_ids_error:
                print("No servers found")
                return jsonify({"error": "No servers found"}), 404

            # Server IDs associated with Project ID fetched successfully
            if not project_ids_error:
                # Set up SSH keys on filtered servers
                key_ids, key_error = create_ssh_keys_on_servers(access_token, project_server_ids, pub_key)
                if key_error:
                    return key_error, 500
                
                # SSH setup successful. Return SSH key IDs
                else:
                    task_id = export_keys(key_ids, email, project_server_ids)
                    return jsonify({"task_id": task_id}), 200
            
            # Error fetching server IDs
            else:
                return project_ids_error, 500
        
        # Set up SSH key on specific server.
        elif server_id:
            server_exists, error = verify_server_id(access_token, server_id)
            if server_exists == 0 and error:
                return error

            if server_exists == 1:
                server_ids = [server_id]
                key_ids, key_error = create_ssh_keys_on_servers(access_token, server_ids, pub_key)
                # SSH key setup failed.
                if key_error:
                    return key_error, 500
                
                # SSH setup successful. Return SSH key IDs
                else:
                    task_id = export_keys(key_ids, email, server_ids)
                    return jsonify({"task_id": task_id}), 200
            else:
                return error, 404
            
        # Project/Server ID not provided. Setup SSH keys on all running servers    
        else:
            server_ids, id_error = get_server_ids(access_token)
            if not server_ids and not id_error:
                print("No servers found")
                return jsonify({"error": "No servers found"}), 404

            # Server list fetched successfully
            if not id_error:
                key_ids, key_error = create_ssh_keys_on_servers(access_token, server_ids, pub_key)
                # SSH key setup failed.
                if key_error:
                    return key_error, 500
                
                # SSH setup successful. Return SSH key IDs
                else:
                    task_id = export_keys(key_ids, email, server_ids)
                    return jsonify({"task_id": task_id}), 200
            
            # Error fetching server IDs
            else:
                return id_error, 500
    else:
        return jsonify({"error": "Invalid route/request method"}), 404

if __name__ == "__main__":
    app.run(debug=True)