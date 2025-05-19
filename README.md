# Server Setup

This repository contains scripts for setting up a production-ready Ubuntu 22.04 server with Kubernetes and Docker.

## Prerequisites

- Freshly installed Ubuntu 22.04
- Root access

## Usage

1. Clone this repository to your server.
2. Run the `server-setup.sh` script: `./server-setup.sh`
3. Follow the prompts to configure the server.

## Configuration

The `server-setup.sh` script sources configuration variables from `configs/config-loader.sh`. You can modify the `.env` file to set the necessary variables.

## Modular Setup Scripts

The setup process is divided into modular scripts located in the `scripts/` directory. Each script handles a specific aspect of the server setup, such as system preparation, user management, SSH hardening, firewall setup, security measures, containerization, backup, and monitoring.

## Logging System

This project includes a comprehensive logging system implemented in `logs/log-utils.sh` with the following features:

### Key Features

- **Color-coded output**: Distinct colors for different log levels (info=blue, success=green, warning=yellow, error=red)
- **Timestamps**: All log entries include date/time stamps
- **Log levels**: Configurable severity filtering (ERROR, WARNING, INFO, SUCCESS)
- **Error tracing**: Automatic stack trace capture on errors
- **Log rotation**: Automatic log file rotation at 10MB by default
- **Syslog integration**: Optional system log forwarding

### Usage

The logging functions are pre-integrated with `server-setup.sh`, but can be used in custom scripts by:

1. Sourcing the library: `source logs/log-utils.sh`
2. Using the logging functions:

```bash
log_info "Informational message"
log_success "Operation succeeded"
log_warning "Warning message"
log_error "Error message"
```

### Configuration

Adjust behavior through environment variables before running scripts:

- `LOG_LEVEL`: Set minimum severity to display (default: SUCCESS)
- `LOG_FILE`: Custom log file path (default: `logs/setup-logs.txt`)
- `USE_SYSLOG`: Set to 1 to enable syslog integration
- `LOG_ROTATE_SIZE`: Change log rotation threshold (default: 10M)

### Error Handling

All scripts automatically trap errors and log detailed diagnostics including:

- Script name and path
- Function name
- Line number
- Full stack trace

## Documentation

Detailed documentation on the server setup process can be found in the `00-docs/` directory.

## Docker Setup (Testing Only)

This repository includes a `docker-compose.yml` file for testing purposes. The Docker container provides a limited environment to test basic functionality, but some scripts may fail as full functionality is not available in the container.

To use the Docker setup:

1. Ensure Docker and Docker Compose are installed on your system
2. Navigate to the repository root directory
3. Start the container:

```bash
docker-compose up -d
```

4. Access the container's shell:

```bash
docker exec -it ubuntu-server bash
```

5. Inside the container, navigate to the repository directory:

```bash
cd /mnt/host
```

6. Run the setup script or test individual components as needed

```bash
bash server-setup.sh
```

**Note:** For full functionality and to test all scripts successfully, use a virtual machine or physical server.
