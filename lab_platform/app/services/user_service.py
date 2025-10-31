from app.utils.db_utils import get_connection

def create_user(name, email):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO users (name, email) VALUES (?, ?)", (name, email))
    conn.commit()
    conn.close()
    print(f"✅ Usuario '{name}' creado con éxito!")

def list_users():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name, email FROM users")
    rows = cur.fetchall()
    conn.close()
    # Convertir filas en diccionarios
    return [{"id": r[0], "name": r[1], "email": r[2]} for r in rows]

def select_user():
    users = list_users()
    if not users:
        print("⚠️ No hay usuarios. Crea uno primero.")
        return None

    print("\nUsuarios registrados:")
    for idx, u in enumerate(users, 1):
        print(f"[{idx}] {u['name']} - {u['email']}")

    while True:
        user_idx = input("\nSelecciona el número del usuario: ")
        if user_idx.isdigit() and 1 <= int(user_idx) <= len(users):
            return users[int(user_idx)-1]['id']
        else:
            print("❌ Opción no válida, intenta de nuevo.")

def delete_user(user_id):
    conn = get_connection()
    cur = conn.cursor()
    # Confirmar antes de eliminar
    cur.execute("SELECT name, email FROM users WHERE id = ?", (user_id,))
    user = cur.fetchone()
    if not user:
        print("⚠️ Usuario no encontrado.")
        conn.close()
        return

    confirm = input(f"⚠️ Confirma eliminar al usuario '{user[0]}' ({user[1]})? (s/n): ").lower()
    if confirm == "s":
        cur.execute("DELETE FROM users WHERE id = ?", (user_id,))
        conn.commit()
        print(f"🗑 Usuario '{user[0]}' eliminado con éxito.")
    else:
        print("❌ Eliminación cancelada.")
    conn.close()

def edit_user(user_id):
    conn = get_connection()
    cur = conn.cursor()
    # Verificar que el usuario exista
    cur.execute("SELECT name, email FROM users WHERE id = ?", (user_id,))
    user = cur.fetchone()
    if not user:
        print("⚠️ Usuario no encontrado.")
        conn.close()
        return

    print(f"\n✏️ Editando usuario '{user[0]}' ({user[1]})")
    new_name = input("Nuevo nombre (enter para mantener actual): ")
    new_email = input("Nuevo email (enter para mantener actual): ")

    # Si el usuario presiona enter, mantener los datos actuales
    if not new_name:
        new_name = user[0]
    if not new_email:
        new_email = user[1]

    cur.execute("UPDATE users SET name = ?, email = ? WHERE id = ?", (new_name, new_email, user_id))
    conn.commit()
    print(f"✅ Usuario actualizado: {new_name} - {new_email}")
    conn.close()
