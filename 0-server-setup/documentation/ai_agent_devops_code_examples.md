# AI Agent DevOps Code Examples

This document provides standalone examples of bash scripts demonstrating best practices and robust scripting techniques for DevOps tasks.

## Complex File Operations

### Example: Secure File Backup

```bash
#!/bin/bash

# Backup important configuration files securely
backup_config_files() {
  local source_dir="/etc/config"
  local backup_dir="/backup/config"
  local timestamp=$(date +"%Y%m%d_%H%M%S")

  # Create backup directory if it doesn't exist
  mkdir -p "$backup_dir"

  # Copy files with preservation of permissions
  cp -rp "$source_dir" "$backup_dir/config_$timestamp"

  # Log the backup operation
  echo "Backup created at $backup_dir/config_$timestamp" >> /var/log/backup.log
}

backup_config_files
```

## Process Management

### Example: Managing a Service with Graceful Restart

```bash
#!/bin/bash

# Gracefully restart a service with logging
restart_service() {
  local service_name="example_service"

  # Check if service is running
  if systemctl is-active --quiet "$service_name"; then
    # Log restart attempt
    echo "Restarting $service_name at $(date)" >> /var/log/service.log

    # Restart the service
    systemctl restart "$service_name"

    # Check restart status
    if [ $? -eq 0 ]; then
      echo "Successfully restarted $service_name" >> /var/log/service.log
    else
      echo "Failed to restart $service_name" >> /var/log/service.log
    fi
  else
    echo "$service_name is not running" >> /var/log/service.log
  fi
}

restart_service
```

## Error Handling and Logging

### Example: Robust Error Handling in Scripts

```bash
#!/bin/bash

# Example function with error handling
process_data() {
  local input_file="$1"

  # Check if input file exists
  if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found" >&2
    return 1
  fi

  # Process the file
  cat "$input_file" | while read line; do
    # Simulate processing with error handling
    if ! process_line "$line"; then
      echo "Warning: Failed to process line: $line" >> /var/log/process.log
    fi
  done
}

# Main execution with error handling
if ! process_data "input.txt"; then
  echo "Processing failed" >&2
  exit 1
fi
```

## Integration with Other Tools

### Example: Integrating with Monitoring Tools

```bash
#!/bin/bash

# Check system metrics and send to monitoring server
check_system_metrics() {
  local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
  local mem_usage=$(free | awk '/Mem:/ {printf "%.2f", $3/$2 * 100}')

  # Send metrics to monitoring server
  curl -s -X POST \
    http://monitoring-server/metrics \
    -H 'Content-Type: application/json' \
    -d "{\"cpu\": $cpu_usage, \"memory\": $mem_usage}"
}

check_system_metrics
```

These examples demonstrate best practices in bash scripting for DevOps tasks, including:

1. Complex file operations with proper permission handling
2. Graceful process management with logging
3. Robust error handling mechanisms
4. Integration with other system tools and services

The scripts include:

- Proper error checking and handling
- Logging mechanisms for traceability
- Secure file operations
- Integration with system services

To use these examples:

1. Copy the relevant script to your desired location
2. Modify the script as needed for your specific use case
3. Make the script executable with `chmod +x script_name.sh`
4. Execute the script with appropriate permissions
