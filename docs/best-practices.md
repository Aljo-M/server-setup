### best-practices.md

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Script Structure & Style](#script-structure--style)
3. [Configuration Management](#configuration-management)
4. [Error Handling](#error-handling)
5. [Logging & Auditing](#logging--auditing)
6. [Security Best Practices](#security-best-practices)
7. [Idempotency & State Checks](#idempotency--state-checks)
8. [External Downloads & Verification](#external-downloads--verification)
9. [Testing & Validation](#testing--validation)
10. [Deployment & Maintenance](#deployment--maintenance)
11. [Additional Enhancements](#additional-enhancements)
12. [Appendix: Further Reading](#appendix-further-reading)
13. [Production-Ready Script Essentials](#production-ready-script-essentials)
14. [Deployment & Maintenance](#deployment--maintenance)
15. [Additional Enhancements](#additional-enhancements)
16. [Appendix: Further Reading](#appendix-further-reading)
17. [Production-Ready Script Essentials](#production-ready-script-essentials)
18. [Deployment & Maintenance](#deployment--maintenance)
19. [Additional Enhancements](#additional-enhancements)
20. [Appendix: Further Reading](#appendix-further-reading)
21. [Production-Ready Script Essentials](#production-ready-script-essentials)
22. [Deployment & Maintenance](#deployment--maintenance)
23. [Additional Enhancements](#additional-enhancements)
24. [Appendix: Further Reading](#appendix-further-reading)

## Prerequisites

### Shebang & Strict Modes

Always start with:

```bash
#!/usr/bin/env bash
set -E -e -u -o pipefail
```

Here's what each flag does:

- `-E`: Causes any trap on `ERR` to be inherited by functions, command substitutions, and commands executed in a subshell environment. This is useful for ensuring that error handling is propagated throughout the script.
- `-e`: Causes the shell to exit immediately if a command exits with a non-zero status. This helps catch errors early and prevents the script from continuing with potentially incorrect or inconsistent state.
- `-u`: Causes the shell to treat unset variables as an error. This helps prevent bugs caused by typos or uninitialized variables.
- `-o pipefail`: Causes a pipeline (i.e., a sequence of commands separated by `|`) to return a failure status if any command in the pipeline fails. This helps ensure that errors are properly propagated through pipelines.

By using these flags, you can make your Bash scripts more robust and reliable.

### Root/User Validation

Immediately verify you have the correct privileges:

```bash
if [[ $EUID -ne 0 ]]; then
  echo "=== ❌ Must run as root. ==="; exit 1
fi
```

Prevents partial failures when non-root users run privileged operations

## Script Structure & Style

### Modular Script Design

Instead of having a single monolithic script, consider breaking it down into multiple smaller scripts, each responsible for a specific task. For example, you can have separate scripts for:

- System upgrades
- SSH hardening
- UFW configuration
- Password policy enforcement

## 13. Production-Ready Script Essentials

Scripts destined for production must go beyond correctness and security; they need robust lifecycle management, seamless automation, and observability to thrive in real-world environments.

### Versioning & Packaging

Scripts should be versioned using semantic versioning in source control and packaged into distribution formats such as Debian packages or container images for predictable deployments :contentReference[oaicite:0]{index=0}.

### CI/CD Integration

Automate linting, testing, and deployment of scripts within CI pipelines (e.g., GitLab CI, GitHub Actions), ensuring changes are validated before reaching production :contentReference[oaicite:1]{index=1}.

### Automated Testing

Use testing frameworks like Bats or shunit2 to write unit and integration tests for scripts, verifying behavior across edge cases and idempotency :contentReference[oaicite:2]{index=2}.

### Release Management

Maintain a `CHANGELOG.md` and tag releases in Git to track changes, fixes, and enhancements—enabling easy rollback and auditability :contentReference[oaicite:3]{index=3}.

### Distribution & Installation

Package scripts as `.deb` files using Debian packaging standards or deliver via configuration-management tools (Ansible roles, Chef cookbooks) to manage versions and dependencies :contentReference[oaicite:4]{index=4}.

### Observability & Metrics

Emit simple metrics (e.g., execution success/failure counts, execution time) via StatsD or Prometheus exporters to monitor script health in production environments :contentReference[oaicite:5]{index=5}.

### Containerization

Consider placing scripts into lightweight Docker images to ensure consistent runtime environments and simplify distribution :contentReference[oaicite:6]{index=6}.

This approach improves maintainability and makes it easier to manage complex setup processes.

### Consistent Naming & Comments

Use descriptive names for your scripts and variables. Comment each script's purpose and any complex logic within the code. Example:

```bash
# server-setup.sh: Main script to configure and harden the server
```

### Utility Functions

While your main script may not use functions directly, consider organizing utility functions in separate files (e.g., `input_utils.sh`, `ask_yes_no.sh`) to promote code reuse and readability.

### ShellCheck Linting

Run `shellcheck` on every script to catch quoting issues, unused variables, and common pitfalls
[GitHub](https://github.com/koalaman/shellcheck).

## Configuration Management

### Centralized Config File

Store defaults in a `variables.conf` (or `.env`) and load via a loader script (`source variable_loader.sh`)

### Command-Line Overrides

Parse `--ssh-port`, `--ufw-ports` flags to override defaults, providing a `--help` output listing all options and descriptions.

### Environment Variable Quoting

Always quote expansions:

```bash
echo "SSH port is $SSH_PORT"
ufw allow "${SSH_PORT}/tcp"
```

Prevents word-splitting and globbing bugs
[DEV Community](https://dev.to).

## Error Handling

### Traps for Diagnostics

Install an `ERR` trap to log the failing command and line:

```bash
trap 'echo "[ERROR] at line ${LINENO}: ${BASH_COMMAND}" >&2; exit 1' ERR
```

Provides actionable debugging info on failure
[Unix & Linux Stack Exchange](https://unix.stackexchange.com).

### Check Exit Codes Explicitly

For critical external commands (e.g. `curl`, `apt-get`), test and bail with a clear message:

```bash
curl -fsSL "$URL" -o file.tar.gz || { echo "Download failed"; exit 1; }
```

Avoids silent cascades of errors
[The world's open source leader](https://www.redhat.com).

## Logging & Auditing

### Central Log File

Redirect `stdout`/`stderr` to both console and a timestamped log:

```bash
LOGFILE="/var/log/setup_server.log"
exec > >(tee -a "$LOGFILE") 2>&1
echo "[INFO] Starting setup at $(date)"
```

Ensures an auditable trail of all actions
[Graham Watts](https://www.gwatts.com).

### Syslog Integration

Where appropriate, use `logger`:

```bash
logger -t setup_server "[INFO] Completed UFW configuration"
```

Sends key events to centralized syslog servers
[Ask Ubuntu](https://askubuntu.com).

## Security Best Practices

### Least Privilege

Run non-privileged parts of the script with `sudo -u deployer` or drop capabilities when possible.

### Input Validation

Sanitize user-provided values:

```bash
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]]; then
  echo "Invalid port"; exit 1
fi
```

Prevents injection or invalid parameters.

### Secure Config File Permissions

Ensure `variables.conf` and generated files (`99-harden.conf`) are owned by `root:root` and mode `0644` or stricter.

### Backup Before Changes

Always back up critical files with timestamps (e.g. `/etc/ssh/sshd_config.bak.$(date +%F-%H%M%S)`) to allow rollbacks.

## Idempotency & State Checks

### Lockfiles

Create a lock at `/var/run/setup_server.lock` on first successful run; exit early if present
[Hacker News](https://news.ycombinator.com).

### Guarded Commands

Before modifying UFW or sysctl, check if the desired state already exists:

```bash
ufw status | grep -qw "80/tcp" || ufw allow 80/tcp
```

Ensures re-running the script doesn’t duplicate changes
[Fatih Arslan](https://arslan.io).

## External Downloads & Verification

### Secure Fetch

Use `curl -fsSL` with certificate enforcement; avoid piping unverified scripts directly into `sh`.

### GPG Key Validation

After downloading a GPG key (e.g. Kubernetes APT repo), verify its fingerprint matches the vendor’s published value.

## Testing & Validation

### Dry-Run Mode

Provide a `--dry-run` flag that echoes commands instead of executing them.

### Automated Post-Checks

After each major step, run simple tests (e.g. `ufw status`, `sshd -t`, `which docker`) and exit non-zero on failures.

### Continuous Integration

Include your scripts in a CI pipeline (using `shellcheck`, `bats`/`shunit2` tests) to catch regressions.

## Deployment & Maintenance

### Version Pinning

Pin external dependencies (e.g. Kubernetes version) in a single variable. Update centrally when necessary.

### Documentation & Usage

Supply a `README.md` with example invocations, required environment variables, and list of produced artifacts (lockfile, logs).

### Linter & Formatter

Enforce style with `shellcheck` and optionally a formatter like `shfmt` in pre-commit hooks.

## Additional Enhancements

### Rollback Traps

Use an `EXIT` trap to restore backups if the script fails partway.

### Parallel/Multi-Node Execution

For clusters, integrate with Ansible or a lightweight orchestrator to run in parallel across nodes.

### Metrics & Monitoring

Emit metrics (e.g. via StatsD or Prometheus) on success/failure counts for automated alerting.

## Appendix: Further Reading

- [Bash scripting best practices — SAP](https://sap1ens.com)
- [ShellCheck static analysis tool — GitHub](https://github.com/koalaman/shellcheck)
- [Correct use of ERR traps — Unix.SE](https://unix.stackexchange.com)
- [Configuring syslog for scripts — AskUbuntu](https://askubuntu.com)
- [Writing idempotent scripts — Arslan.io](https://arslan.io)
- [Using ShellCheck in CI — DEV Community](https://dev.to)
- [The Bash Trap Trap — Medium](https://medium.com)
- [Logging in bash scripts — Graham Watts](https://www.gwatts.com)
- [Idempotent script patterns — Hacker News](https://news.ycombinator.com)
- [Red Hat on error handling — Red Hat](https://www.redhat.com)
