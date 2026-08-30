import os

base_dir = r"C:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0"

def write_file(rel_path, content):
    full_path = os.path.join(base_dir, rel_path.replace("/", os.sep))
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write(content.strip() + "\r\n")
    print(f"Generated: {rel_path}")

print("Builder initialized.")
