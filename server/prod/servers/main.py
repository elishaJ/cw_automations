import functions_framework
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)
BASE_URL = "https://api.cloudways.com/api/v1"
EZ_API = 'https://us-central1-cw-automations.cloudfunctions.net'

# Function to get Ouath access token from Authorization header
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
def get_server_ips(server_list):
    running_servers = [server['public_ip'] for server in server_list if server['status'] == 'running']
    return running_servers

# Function to get running server IDs
def get_server_ids(server_list):
    server_ids = [server['id'] for server in server_list if server['status'] == 'running']
    return server_ids

# Function to get master usernames
def get_master_usernames(server_list):
    master_usernames = [server['master_user'] for server in server_list if server['status'] == 'running']
    return master_usernames

# Main function
def main(request):
    route = request.path

    # Get the requested resource based on the route
    # Route to get Server IPs
    if route == '/ips' and request.method == 'GET':
        access_token = extract_access_token(request)
        if not access_token:
            return jsonify({"error": "Access token is required"}), 400
        else: 
            server_list, error = get_server_list(access_token)
            if not error:
                server_ips=get_server_ips(server_list)
                return jsonify({"public_ip": server_ips}), 200
            else:
                return error, 500

    # Route to get Server IDs
    elif route == '/ids' and request.method == 'GET':
        access_token = extract_access_token(request)
        if not access_token:
            return jsonify({"error": "Access token is required"}), 400
        else: 
            server_list, error = get_server_list(access_token)
            if not error:
                server_ids=get_server_ids(server_list)
                return jsonify({"id": server_ids}), 200
            else:
                return error, 500
    
    # Route to get Server Master usernames
    elif route == '/users' and request.method == 'GET':
        access_token = extract_access_token(request)
        if not access_token:
            return jsonify({"error": "Access token is required"}), 400
        else: 
            server_list, error = get_server_list(access_token)
            if not error:
                users=get_master_usernames(server_list)
                return jsonify({"master_user": users}), 200
            else:
                return error, 500
    else:
        return jsonify({"error": "Invalid route/request method"}), 404

# Route for getting server IPs
@app.route('/ips', methods=['GET'])
def get_server_ips_route():
    return main(request)

# Route for getting server IDs
@app.route('/ids', methods=['GET'])
def get_server_ids_route():
    return main(request)

# Route for getting master usernames
@app.route('/users', methods=['GET'])
def get_master_usernames_route():
    return main(request)

if __name__ == "__main__":
    app.run(debug=True)