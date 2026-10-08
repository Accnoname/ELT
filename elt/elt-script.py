import os
import subprocess
import time

def wait_for_postgres(host, port="5432", max_retries=20, delay_seconds=5):
    """Wait until the PostgreSQL server is ready to accept connections."""
    retries = 0
    print(f"[*] Checking connection to PostgreSQL at {host}:{port}...")
    while retries < max_retries:
        try:
            result = subprocess.run(
                ["pg_isready", "-h", host, "-p", str(port)],
                check=True,
                capture_output=True,
                text=True
            )
            if "accepting connections" in result.stdout:
                print(f"[✓] Postgres at {host}:{port} is ready.")
                return True
        except subprocess.CalledProcessError:
            retries += 1
            print(f"[!] {host}:{port} not ready yet. Retrying in {delay_seconds}s ({retries}/{max_retries})...")
            time.sleep(delay_seconds)

    print(f"[✗] Max retries reached for {host}:{port}. Exiting.")
    return False

source_config = {
    'dbname': 'source_db',
    'user': 'postgres',
    'password': 'secret',
    'host': 'source_postgres',
    'port': '5432',
}

destination_config = {
    'dbname': 'destination_db',
    'user': 'postgres',
    'password': 'secret',
    'host': 'destination_postgres',
    'port': '5432',
}

dump_file = "source_dump.sql"

# 1. Health checks on both source and destination
if not wait_for_postgres(host=source_config['host'], port=source_config['port']):
    exit(1)
if not wait_for_postgres(host=destination_config['host'], port=destination_config['port']):
    exit(1)

# 2. Extract (pg_dump) with clean drop-and-replace flags for idempotency
# --clean: drops objects before recreation
# --if-exists: adds IF EXISTS to drop commands to prevent errors on initial load
# --no-owner, --no-privileges: eliminates permission mismatches across environments
dump_command = [
    "pg_dump",
    "-h", source_config['host'],
    "-p", source_config['port'],
    "-U", source_config['user'],
    "-d", source_config['dbname'],
    "-w",
    "--clean",
    "--if-exists",
    "--no-owner",
    "--no-privileges",
    "-f", dump_file
]

print("[*] Extracting data from source database (idempotent snapshot)...")
subprocess_env_src = dict(os.environ, PGPASSWORD=source_config['password'])
subprocess.run(dump_command, env=subprocess_env_src, check=True)
print("[✓] Extraction complete.")

# 3. Load (psql) into destination database
load_command = [
    "psql",
    "-h", destination_config['host'],
    "-p", destination_config['port'],
    "-U", destination_config['user'],
    "-d", destination_config['dbname'],
    "-a",
    "-f", dump_file
]

print("[*] Loading extracted snapshot into destination database...")
subprocess_env_dest = dict(os.environ, PGPASSWORD=destination_config['password'])
subprocess.run(load_command, env=subprocess_env_dest, check=True)
print("[✓] Load complete.")

# 4. Cleanup temporary artifacts
if os.path.exists(dump_file):
    os.remove(dump_file)
    print(f"[✓] Cleaned up temporary dump file: {dump_file}")

print("\n[✓] EL PIPELINE FINISHED SUCCESSFULLY (IDEMPOTENT RUN)")