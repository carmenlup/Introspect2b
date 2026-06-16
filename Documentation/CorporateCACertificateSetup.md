# Corporate CA Certificate Setup for ACR Access

## Why this is needed

On corporate networks, outbound HTTPS traffic is often routed through a TLS-inspection proxy.
The proxy decrypts and re-encrypts traffic using its own root CA certificate — one that is not in
the default trust store of the Azure CLI or Docker. This causes certificate validation errors like:

```
SSLError: HTTPSConnectionPool: Max retries exceeded ...
certificate verify failed: unable to get local issuer certificate
```

The correct fix is to **add your corporate root CA to the tool trust stores** — not to disable SSL inspection.
Disabling SSL inspection (an "SSL bypass") creates a blind spot in encrypted traffic and is a security risk.

---

## Step 1 — Obtain the corporate root CA certificate

Request the root CA certificate from your IT/security team. It will be a `.crt` or `.pem` file.
If you are unsure which file to use, your IT team can confirm the correct one.

You can also export it from your OS certificate store if it is already trusted by your machine:

**Windows** — open `certmgr.msc`, navigate to **Trusted Root Certification Authorities → Certificates**,
find the corporate CA, right-click → **Export** → Base-64 encoded X.509 (.CER), save as `corporate-ca.crt`.

---

## Step 2 — Configure the Azure CLI

The Azure CLI uses Python's `requests` library which reads its CA bundle from the `REQUESTS_CA_BUNDLE`
environment variable.

Create a combined bundle that includes both the default CA bundle and your corporate certificate:

```bash
# Find the default CA bundle used by the Azure CLI's Python environment
python3 -c "import certifi; print(certifi.where())"

# Copy the default bundle and append the corporate certificate
cp $(python3 -c "import certifi; print(certifi.where())") ~/combined-ca-bundle.pem
cat /path/to/corporate-ca.crt >> ~/combined-ca-bundle.pem
```

Set the environment variable (add this to your shell profile to make it permanent):

```bash
export REQUESTS_CA_BUNDLE=~/combined-ca-bundle.pem
```

**Windows (PowerShell):**

```powershell
$env:REQUESTS_CA_BUNDLE = "$env:USERPROFILE\combined-ca-bundle.pem"
```

To make it permanent on Windows, add it via System Properties → Environment Variables.

Verify the Azure CLI now connects correctly:

```bash
az acr show --name introspect2bacr --resource-group introspect-2-b --query loginServer
```

---

## Step 3 — Configure Docker

Docker uses its own certificate store, separate from the OS and the Azure CLI.

**Linux:**

```bash
sudo cp /path/to/corporate-ca.crt /usr/local/share/ca-certificates/corporate-ca.crt
sudo update-ca-certificates
sudo systemctl restart docker
```

**macOS (Docker Desktop):**

1. Open **Keychain Access**.
2. Import the corporate CA certificate into the **System** keychain.
3. Double-click the certificate → **Trust** → set **When using this certificate** to **Always Trust**.
4. Restart Docker Desktop.

**Windows (Docker Desktop):**

1. Double-click the `.crt` file → **Install Certificate**.
2. Choose **Local Machine** → **Trusted Root Certification Authorities**.
3. Restart Docker Desktop.

Verify Docker can reach ACR after the restart:

```bash
az acr login --name introspect2bacr
docker pull introspect2bacr.azurecr.io/claimstatus:latest
```

---

## Step 4 — Configure the Azure DevOps pipeline agent (self-hosted agents only)

Microsoft-hosted agents (`ubuntu-latest`) already trust public CAs used by Azure services — no action needed.

If your organisation uses **self-hosted agents** behind the same proxy, apply steps 2 and 3 on the agent machine.
For the `REQUESTS_CA_BUNDLE` variable, set it as a pipeline variable or in the agent's service environment:

```yaml
# In azure-pipelines.yml, under the job or stage that runs az acr login
variables:
  REQUESTS_CA_BUNDLE: /path/to/combined-ca-bundle.pem
```

---

## Verification checklist

| Check | Command |
|---|---|
| Azure CLI trusts ACR endpoint | `az acr show --name introspect2bacr --resource-group introspect-2-b` |
| ACR login succeeds | `az acr login --name introspect2bacr` |
| Docker pull succeeds | `docker pull introspect2bacr.azurecr.io/claimstatus:latest` |
| Docker push succeeds | `docker push introspect2bacr.azurecr.io/claimstatus:latest` |

---

## Summary

| Tool | Trust store mechanism |
|---|---|
| Azure CLI | `REQUESTS_CA_BUNDLE` environment variable |
| Docker (Linux) | `/usr/local/share/ca-certificates/` + `update-ca-certificates` |
| Docker (macOS) | macOS System Keychain |
| Docker (Windows) | Windows Certificate Store — Trusted Root CAs |
| Azure DevOps (Microsoft-hosted) | No action needed — public CAs are trusted by default |
| Azure DevOps (self-hosted) | Same as Azure CLI + Docker on the agent OS |
