import functions_framework
import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)
BASE_URL = "https://api.cloudways.com/api/v1"

def get_params():
    email = request.args.get('email') or os.getenv('CLOUDWAYS_EMAIL')
    api_key = request.args.get('api_key') or os.getenv('CLOUDWAYS_API_KEY')

    # Check if the request contains JSON data
    if (not email or not api_key) and request.content_type == 'application/json':
        data = request.json
        if data:
            email = email or data.get('email')
            api_key = api_key or data.get('api_key')
    
    elif (not email or not api_key) and request.content_type == 'application/x-www-form-urlencoded':
        email = request.form.get('email')
        api_key = request.form.get('api_key')
    return email, api_key

def get_access_token(email, api_key):
    is_error = 0
    response = requests.post(BASE_URL + '/oauth/access_token', json={"email": email, "api_key": api_key})
    if response.status_code != 200:
        is_error = 1
        access_token = None
    else:
        access_token = response.json().get('access_token')
        if not access_token:
            is_error = 1
    return access_token, is_error

@app.route('/token', methods=['POST'])
def main(request):
    if request.method == 'POST':
        email, api_key = get_params()
        # If email or API key is missing, return an error response
        if not email or not api_key:
            return jsonify({"error": "Email and API key are required"}), 400
        
        access_token, is_error = get_access_token(email, api_key)

        # Check if access token was retreived
        if is_error:
            return jsonify({"error": "Unable to retrieve access token. Invalid parameters provided"}), 401
        else:
            return jsonify({"token": access_token}), 200
    else:
        return jsonify({"error": "Invalid route/request method"}), 404

if __name__ == "__main__":
    app.run(debug=True)