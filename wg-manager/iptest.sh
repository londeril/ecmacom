#!/bin/bash

# Function to get the next available IP address
get_next_ip() {
  local subnet="$1"
  local db_file="$2"

  # Use ipcalc to get network information
  local network=$(ipcalc -n "$subnet" | cut -d= -f2)   # this is AI bullshit
  local broadcast=$(ipcalc -b "$subnet" | cut -d= -f2) # this is AI bullshit
  local prefix=$(ipcalc -p "$subnet" | cut -d= -f2)    # this is AI bullshit

  # Extract the base IP
  IFS='.' read -r -a ip_parts <<<"$network"
  local base_ip="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}"

  # Start from the second usable IP (first usable IP is typically gateway)
  local start_ip=$((ip_parts[3] + 2))
  local end_ip=$(($(ipcalc -h "$subnet" | cut -d= -f2 | cut -d. -f4) - 1))

  for ((i = start_ip; i <= end_ip; i++)); do
    local current_ip="${base_ip}.$i"
    if ! grep -q "$current_ip" "$db_file"; then
      echo "$current_ip"
      return 0
    fi
  done

  echo "No available IP addresses in the subnet" >&2
  return 1
}

# Example usage
SUBNET="10.0.100.0/24"
DB_FILE="./db_file"

next_ip=$(get_next_ip "$SUBNET" "$DB_FILE")
if [ $? -eq 0 ]; then
  echo "Next available IP: $next_ip"
else
  echo "Failed to find an available IP"
fi
