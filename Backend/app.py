# app.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from spotify_api import get_playlist_by_mood
import jwt
from datetime import datetime, timedelta
from functools import wraps
import os
from dotenv import load_dotenv
import mysql.connector
from mysql.connector import Error

# -------------------------------------------------
# Config
# -------------------------------------------------
load_dotenv()  # .env dosyasını yükle

SECRET_KEY = os.getenv("SECRET_KEY", "harmonist_secret_key")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASS", ""),
    "database": os.getenv("DB_NAME", "mood_app"),
    "auth_plugin": os.getenv("DB_AUTH_PLUGIN", "mysql_native_password"),
}

app = Flask(__name__)
CORS(app)  # Flutter'dan gelen isteklere izin ver

# -------------------------------------------------
# Token doğrulama decorator
# -------------------------------------------------
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({"message": "Token eksik!"}), 401

        try:
            token = token.split(" ")[1]  # "Bearer <token>"
            data = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            current_user_id = data["user_id"]
        except Exception:
            return jsonify({"message": "Token geçersiz!"}), 401

        return f(current_user_id, *args, **kwargs)
    return decorated

# -------------------------------------------------
# DB helpers
# -------------------------------------------------
def get_db():
    """Yeni bir MySQL bağlantısı aç."""
    return mysql.connector.connect(**DB_CONFIG)

def init_db():
    """Gerekli tabloyu oluştur (yoksa)."""
    conn = get_db()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
              id INT AUTO_INCREMENT PRIMARY KEY,
              username VARCHAR(50) NOT NULL UNIQUE,
              password_hash VARCHAR(255) NOT NULL,
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            """
        )
        conn.commit()
    finally:
        cur.close()
        conn.close()

# -------------------------------------------------
# Auth endpoints
# -------------------------------------------------
@app.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    password = (data.get("password") or "").strip()

    if not username or not password:
        return jsonify({"error": "Username and password are required."}), 400

    pwd_hash = generate_password_hash(password)

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)

        # kullanıcı var mı bakalım
        cur.execute("SELECT id FROM users WHERE username=%s", (username,))
        if cur.fetchone():
            return jsonify({"error": "Username is already taken."}), 409

        # ekle (password_hash sütununa yazıyoruz)
        cur.execute(
            "INSERT INTO users (username, password_hash) VALUES (%s, %s)",
            (username, pwd_hash),
        )
        conn.commit()
        return jsonify({"message": "User registered successfully."}), 201
    except Error as e:
        return jsonify({"error": f"DB error: {e}"}), 500
    finally:
        cur.close()
        conn.close()

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    password = (data.get("password") or "").strip()

    if not username or not password:
        return jsonify({"error": "Username and password are required."}), 400

    conn = get_db()
    try:
        cur = conn.cursor(dictionary=True)
        # password_hash sütununu çekiyoruz
        cur.execute("SELECT id, password_hash FROM users WHERE username=%s", (username,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "Invalid username or password."}), 401

        if not check_password_hash(row["password_hash"], password):
            return jsonify({"error": "Invalid username or password."}), 401

        token = jwt.encode({
            "user_id": row["id"],
            "exp": datetime.utcnow() + timedelta(hours=24)
        }, SECRET_KEY)

        return jsonify({
            "message": "Login successful.",
            "user_id": row["id"],
            "token": token
        }), 200
    except Error as e:
        return jsonify({"error": f"DB error: {e}"}), 500
    finally:
        cur.close()
        conn.close()

# -------------------------------------------------
# Spotify playlist endpointler
# -------------------------------------------------
@app.route("/get_playlist", methods=["GET"])
@token_required
def get_playlist(current_user_id):
    mood = request.args.get("mood", "").lower()
    if not mood:
        return jsonify({"error": "Mood parameter is required"}), 400

    try:
        tracks = get_playlist_by_mood(mood)
        return jsonify(tracks)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# -------------------------------------------------
# Maini
# -------------------------------------------------
if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=True)
