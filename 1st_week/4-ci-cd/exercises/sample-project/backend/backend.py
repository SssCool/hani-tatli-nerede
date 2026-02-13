import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS
from threading import Lock

app = Flask(__name__)
CORS(app)

DATA_FILE = 'users.json'
file_lock = Lock()

def read_users():
    if not os.path.exists(DATA_FILE):
        return []
    with file_lock:
        with open(DATA_FILE, 'r') as f:
            return json.load(f)

def write_users(users):
    with file_lock:
        with open(DATA_FILE, 'w') as f:
            json.dump(users, f, indent=4)

@app.route("/register", methods=["POST"])
def register_user():
    data = request.json
    username = data.get("username")
    email = data.get("email")

    users = read_users()
    new_id = (users[-1]["id"] + 1) if users else 1
    users.append({
        "id": new_id,
        "username": username,
        "email": email
    })
    write_users(users)
    return jsonify({"message": "User registered successfullyy"})

@app.route("/list", methods=["GET"])
def list_users():
    users = read_users()
    return jsonify([[u["id"], u["username"], u["email"]] for u in users])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8090, debug=True)