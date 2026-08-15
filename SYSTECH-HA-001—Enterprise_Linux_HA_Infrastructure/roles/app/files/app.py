import os
import socket
from flask import Flask, jsonify
import pymysql

app = Flask(__name__)

DB_HOST = os.environ.get("DB_HOST")
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASS")
DB_NAME = os.environ.get("DB_NAME")


def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
    )


@app.route("/")
def index():
    try:
        conn = get_connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, name, email FROM customers")
            rows = cursor.fetchall()
        conn.close()
        return jsonify({
            "served_by": socket.gethostname(),
            "customers": rows
        })
    except Exception as e:
        return jsonify({
            "served_by": socket.gethostname(),
            "error": str(e)
        }), 500


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.environ.get("APP_PORT", 8000)))
