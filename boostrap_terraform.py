import subprocess
import sys
from pathlib import Path
import shutil
print("=== Terraform Bootstrap ===")

try:
    remote_url = subprocess.check_output(
        ["git", "remote", "get-url", "origin"],
        text=True
    ).strip()

except Exception:
    print("ERROR: Not a git repository.")
    sys.exit(1)

print(f"Git remote: {remote_url}")

if remote_url.startswith("git@github.com:"):
    repo_path = remote_url.replace(
        "git@github.com:",
        ""
    ).replace(
        ".git",
        ""
    )

elif remote_url.startswith("https://github.com/"):
    repo_path = remote_url.replace(
        "https://github.com/",
        ""
    ).replace(
        ".git",
        ""
    )

else:
    print("ERROR: Unsupported GitHub URL.")
    sys.exit(1)

owner, repo = repo_path.split("/")

print()
print("Detected Repository")
print(f"Owner: {owner}")
print(f"Repository: {repo}")

print()
print("Checking Azure login...")

try:
    account_json = subprocess.check_output(
        [
            "az",
            "account",
            "show",
            "--output",
            "json"
        ],
        text=True
    )

except Exception:
    print()
    print("ERROR: Azure CLI is not logged in.")
    print("Run: az login")
    sys.exit(1)

import json

account = json.loads(account_json)

subscription_id = account["id"]
tenant_id = account["tenantId"]
subscription_name = account["name"]

print()
print("Azure Account")
print(f"Subscription: {subscription_name}")
print(f"Subscription ID: {subscription_id}")
print(f"Tenant ID: {tenant_id}")

print()
print("Checking Terraform State Resource Group...")

state_rg = "rg-terraform-state"

result = subprocess.run(
    [
        "az",
        "group",
        "exists",
        "--name",
        state_rg
    ],
    capture_output=True,
    text=True
)

rg_exists = result.stdout.strip().lower() == "true"

if rg_exists:
    print(f"Resource Group exists: {state_rg}")

else:
    print(f"Resource Group does not exist: {state_rg}")

    answer = input(
        "Create Resource Group? [Y/n]: "
    ).strip().lower()

    if answer not in ["", "y", "yes"]:
        print("Bootstrap cancelled.")
        sys.exit(0)

    print()
    print("Creating Resource Group...")

    subprocess.run(
        [
            "az",
            "group",
            "create",
            "--name",
            state_rg,
            "--location",
            "polandcentral"
        ],
        check=True
    )

    print(
        f"Resource Group created: {state_rg}"
    )

print()
print("Checking Storage Accounts...")

storage_accounts_json = subprocess.check_output(
    [
        "az",
        "storage",
        "account",
        "list",
        "--resource-group",
        state_rg,
        "--output",
        "json"
    ],
    text=True
)

storage_accounts = json.loads(
    storage_accounts_json
)

if len(storage_accounts) == 1:

    storage_account_name = storage_accounts[0]["name"]

    print()
    print(
        f"Using Storage Account: "
        f"{storage_account_name}"
    )

elif len(storage_accounts) > 1:

    print()
    print("Multiple Storage Accounts found:")

    for index, account in enumerate(
        storage_accounts,
        start=1
    ):
        print(
            f"[{index}] {account['name']}"
        )

    choice = int(
        input(
            "Select Storage Account: "
        )
    )

    storage_account_name = storage_accounts[
        choice - 1
    ]["name"]

else:

    print()
    print(
        "No Storage Account found."
    )

    create = input(
        "Create Storage Account? [Y/n]: "
    ).strip().lower()

    if create not in [
        "",
        "y",
        "yes"
    ]:
        print(
            "Bootstrap cancelled."
        )
        sys.exit(0)

    import secrets

    random_suffix = secrets.token_hex(
        4
    )

    storage_account_name = (
        f"tfstate{random_suffix}"
    )

    print()
    print(
        f"Creating Storage Account: "
        f"{storage_account_name}"
    )

    subprocess.run(
        [
            "az",
            "storage",
            "account",
            "create",
            "--name",
            storage_account_name,
            "--resource-group",
            state_rg,
            "--location",
            "polandcentral",
            "--sku",
            "Standard_LRS"
        ],
        check=True
    )

    print(
        "Storage Account created."
    )
print()
print("Checking tfstate container...")

container_name = "tfstate"

container_exists = subprocess.run(
    [
        "az",
        "storage",
        "container",
        "exists",
        "--name",
        container_name,
        "--account-name",
        storage_account_name,
        "--auth-mode",
        "login",
        "--output",
        "json"
    ],
    capture_output=True,
    text=True
)

container_data = json.loads(
    container_exists.stdout
)

if container_data["exists"]:

    print(
        f"Container exists: "
        f"{container_name}"
    )

else:

    print(
        f"Container does not exist: "
        f"{container_name}"
    )

    print(
        "Creating container..."
    )

    subprocess.run(
        [
            "az",
            "storage",
            "container",
            "create",
            "--name",
            container_name,
            "--account-name",
            storage_account_name,
            "--auth-mode",
            "login"
        ],
        check=True
    )

    print(
        "Container created."
    )
print()
print("Generating backend.tf...")

terraform_dir = Path("terraform")

terraform_dir.mkdir(
    exist_ok=True
)

backend_file = (
    terraform_dir / "backend.tf"
)

backend_content = f'''terraform {{
  backend "azurerm" {{
    resource_group_name  = "{state_rg}"
    storage_account_name = "{storage_account_name}"
    container_name       = "{container_name}"
    key                  = "{repo}.tfstate"
  }}
}}
'''

backend_file.write_text(
    backend_content,
    encoding="utf-8"
)

print(
    f"Created: {backend_file}"
)
print()
print("Generating SSH keypair...")

output_dir = Path("output")

output_dir.mkdir(
    exist_ok=True
)

private_key_path = (
    output_dir / "id_ed25519"
)

public_key_path = (
    output_dir / "id_ed25519.pub"
)

if private_key_path.exists():

    print(
        "SSH key already exists."
    )

else:

    if not shutil.which(
        "ssh-keygen"
    ):
        print(
            "ERROR: ssh-keygen not found."
        )
        sys.exit(1)

    subprocess.run(
        [
            "ssh-keygen",
            "-t",
            "ed25519",
            "-N",
            "",
            "-f",
            str(private_key_path)
        ],
        check=True
    )

    print(
        "SSH keypair generated."
    )
print()
print("Checking App Registration...")

app_name = f"{repo}-github-actions"

apps_json = subprocess.check_output(
    [
        "az",
        "ad",
        "app",
        "list",
        "--display-name",
        app_name,
        "--output",
        "json"
    ],
    text=True
)

apps = json.loads(apps_json)

if apps:

    app = apps[0]

    client_id = app["appId"]

    print(
        f"Using existing App Registration: "
        f"{app_name}"
    )

    print(
        f"Client ID: {client_id}"
    )

else:

    print(
        f"Creating App Registration: "
        f"{app_name}"
    )

    created_app_json = subprocess.check_output(
        [
            "az",
            "ad",
            "app",
            "create",
            "--display-name",
            app_name,
            "--output",
            "json"
        ],
        text=True
    )

    created_app = json.loads(
        created_app_json
    )

    client_id = created_app["appId"]

    print(
        f"Created App Registration: "
        f"{app_name}"
    )

    print(
        f"Client ID: {client_id}"
    )

print()
print("Checking Service Principal...")

sp_json = subprocess.check_output(
    [
        "az",
        "ad",
        "sp",
        "list",
        "--filter",
        f"appId eq '{client_id}'",
        "--output",
        "json"
    ],
    text=True
)

service_principals = json.loads(
    sp_json
)

if service_principals:

    print(
        "Using existing Service Principal."
    )

else:

    print(
        "Creating Service Principal..."
    )

    subprocess.run(
        [
            "az",
            "ad",
            "sp",
            "create",
            "--id",
            client_id
        ],
        check=True
    )

    print(
        "Service Principal created."
    )
print()
print("Checking Contributor role assignment...")

role_json = subprocess.check_output(
    [
        "az",
        "role",
        "assignment",
        "list",
        "--assignee",
        client_id,
        "--scope",
        f"/subscriptions/{subscription_id}",
        "--output",
        "json"
    ],
    text=True
)

roles = json.loads(role_json)

contributor_exists = any(
    role["roleDefinitionName"] == "Contributor"
    for role in roles
)

if contributor_exists:

    print(
        "Contributor role already assigned."
    )

else:

    print(
        "Assigning Contributor role..."
    )

    subprocess.run(
        [
            "az",
            "role",
            "assignment",
            "create",
            "--assignee",
            client_id,
            "--role",
            "Contributor",
            "--scope",
            f"/subscriptions/{subscription_id}"
        ],
        check=True
    )

    print(
        "Contributor role assigned."
    )
print()
print("Checking Federated Credential...")

credential_name = "github-actions"

credential_json = subprocess.check_output(
    [
        "az",
        "ad",
        "app",
        "federated-credential",
        "list",
        "--id",
        client_id,
        "--output",
        "json"
    ],
    text=True
)

credentials = json.loads(
    credential_json
)

credential_exists = any(
    credential["name"] == credential_name
    for credential in credentials
)

if credential_exists:

    print(
        "Federated Credential already exists."
    )

else:

    print(
        "Creating Federated Credential..."
    )

    federation_config = {
        "name": credential_name,
        "issuer":
            "https://token.actions.githubusercontent.com",
        "subject":
            f"repo:{owner}/{repo}:ref:refs/heads/main",
        "audiences": [
            "api://AzureADTokenExchange"
        ]
    }

    config_file = (
        Path("output")
        / "federation.json"
    )

    config_file.write_text(
        json.dumps(
            federation_config,
            indent=2
        ),
        encoding="utf-8"
    )

    subprocess.run(
        [
            "az",
            "ad",
            "app",
            "federated-credential",
            "create",
            "--id",
            client_id,
            "--parameters",
            str(config_file)
        ],
        check=True
    )

    print(
        "Federated Credential created."
    )
print()
print("=" * 50)
print("GITHUB VARIABLES")
print("=" * 50)

public_key = public_key_path.read_text(
    encoding="utf-8"
).strip()

print()
print(f"AZURE_CLIENT_ID={client_id}")
print(f"AZURE_TENANT_ID={tenant_id}")
print(
    f"AZURE_SUBSCRIPTION_ID={subscription_id}"
)
print(f"SSH_PUBLIC_KEY={public_key}")

print()
print("=" * 50)
print("GITHUB SECRETS")
print("=" * 50)

private_key = private_key_path.read_text(
    encoding="utf-8"
)

print()
print("SSH_PRIVATE_KEY=")
print(private_key)

print()
print("Creating bootstrap summary...")

summary_file = (
    output_dir / "bootstrap-summary.txt"
)

summary_content = f"""
========================================
GITHUB VARIABLES
========================================

AZURE_CLIENT_ID={client_id}

AZURE_TENANT_ID={tenant_id}

AZURE_SUBSCRIPTION_ID={subscription_id}

SSH_PUBLIC_KEY={public_key}

========================================
GITHUB SECRETS
========================================

SSH_PRIVATE_KEY

Use content from:

{private_key_path}

========================================
BACKEND
========================================

terraform/backend.tf

========================================
"""

summary_file.write_text(
    summary_content,
    encoding="utf-8"
)

print(
    f"Created: {summary_file}"
)
print()

push_backend = input(
    "Push backend.tf to repository? [Y/n]: "
).strip().lower()

if push_backend in [
    "",
    "y",
    "yes"
]:

    print()
    print("Committing backend.tf...")

    subprocess.run(
        [
            "git",
            "add",
            "terraform/backend.tf"
        ],
        check=True
    )

    subprocess.run(
        [
            "git",
            "commit",
            "-m",
            "Configure terraform backend"
        ],
        check=True
    )

    subprocess.run(
        [
            "git",
            "push"
        ],
        check=True
    )

    print(
        "backend.tf pushed successfully."
    )

else:

    print(
        "Skipping git push."
    )
