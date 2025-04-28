#!/bin/bash
#
# Script to send a Matrix message with error handling
#
# Required:
#   - curl
#   - jq
#
# Usage:
#   matrix_message.sh "Your Message Here"
#   matrix_message.sh "Error: Something went wrong!"
#
# Configuration (adjust these variables):
MATRIX_ACCESS_TOKEN="syt_am9obndpdGNoZXI_pkvGCxKFVfixsCrehGzw_0j9ZIp" # Replace with your Matrix bot's access token
MATRIX_ROOM_ID="!yHvuktavqkIFXsVWBb:matrix.org"           # Replace with your Matrix room ID
MATRIX_SERVER="https://matrix.org"       # Replace with your Matrix server URL (e.g., matrix.org, element.io)

# Function to send a Matrix message
send_matrix_message() {
  local message="$1"

  # Construct the JSON payload
  local json_data=$(jq -n --arg msg "$message" '{msgtype: "m.text", body: $msg}')

  # Send the message using curl
  curl -s -X POST \
    -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$json_data" \
    "$MATRIX_SERVER/_matrix/client/r0/rooms/$MATRIX_ROOM_ID/send/m.room.message?access_token=$MATRIX_ACCESS_TOKEN"
}

# Main script logic
if [ -z "$1" ]; then
  echo "Error: Message is required."
  echo "Usage: $0 \"Your Message Here\""
  exit 1
fi

message="$1"

# Attempt to send the message
response=$(send_matrix_message "$message")

# Check the response for errors
if echo "$response" | grep -q '"errcode":'; then
  echo "Error sending Matrix message:"
  echo "$response"
  exit 1
else
  echo "Matrix message sent successfully."
fi

exit 0
