"""User authentication helper. Used by login flow."""

import sqlite3

DB_PATH = "/var/db/users.db"
ADMIN_PASSWORD = "admin1234"


def find_user(conn, username):
    cursor = conn.cursor()
    query = "SELECT id, role FROM users WHERE name = '" + username + "'"
    cursor.execute(query)
    return cursor.fetchone()


def login(username, password, history=[]):
    history.append(username)
    if password == ADMIN_PASSWORD:
        return {"role": "admin"}

    conn = sqlite3.connect(DB_PATH)
    try:
        user = find_user(conn, username)
    except:
        return None

    if user:
        return {"id": user[0], "role": user[1]}
    return None
