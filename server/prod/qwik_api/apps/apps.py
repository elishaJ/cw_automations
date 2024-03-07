import functions_framework
import requests
from flask import Flask, request,jsonify

app = Flask(__name__)
BASE_URL = "https://api.cloudways.com/api/v1"
EZ_API = 'https://us-central1-cw-automations.cloudfunctions.net'

def get_params():
    project_id = request.args.get('project_id')
    server_id = request.args.get('server_id')
    return project_id, server_id

# Function to get Oauth access token from Authorization header
def extract_access_token(request):
    auth_header = request.headers.get('Authorization')
    if auth_header:
        token_type, token = auth_header.split(' ', 1)
        if token_type.lower() == 'bearer':
            return token.strip()
    return None

# Function to fetch server list
def get_server_list(access_token):
    error = None
    server_info = None
    headers = {"Authorization": "Bearer " + access_token}
    response = requests.get(BASE_URL + '/server', headers=headers)
    if response.status_code != 200:
        error = response.text
        return server_info, error
    else:
        server_info = response.json().get('servers', [])
        return server_info, error

# Function to get active/running server IPs
def get_server_ip(server_list):
    running_servers = [server['public_ip'] for server in server_list if server['status'] == 'running']
    return running_servers

def get_apps_with_project_id(server_list, project_id):
    apps = []
    for server in server_list:
        server_id = server.get('id')
        for app in server.get('apps', []):
            if app.get('project_id') == project_id:
                app_id = app.get('id')
                apps.append({"id": app_id, "server_id": server_id})
    return apps


def get_apps_with_server_id(server_list, server_id):
    apps = []
    for server in server_list:
        if server.get('id') == server_id:
            for app in server.get('apps', []):
                app_id = app.get('id')
                apps.append(app_id)
    return apps
    
# Main function
@app.route('/apps', methods=['GET'])
def main(request):

    project_id, server_id = get_params()    
    if not project_id and not server_id:
        return jsonify({"error": "Missing Server/Project ID"}), 400
    
    access_token = extract_access_token(request)
    if not access_token:
        return jsonify({"error": "Access token is required"}), 400
    else: 
        server_list, error = get_server_list(access_token)
        if not error and project_id:
            apps = get_apps_with_project_id(server_list, project_id)
            return jsonify({"apps": apps }), 200

        elif not error and server_id:
            apps = get_apps_with_server_id(server_list, server_id)
            return jsonify({"apps": apps}), 200

        else:
            return error, 500
    
if __name__ == "__main__":
    app.run(debug=True)