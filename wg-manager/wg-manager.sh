#!/bin/bash
# Title: wg-manager.sh
# Author: Daniel Mueller
# Version: 1.2 (8.9.2024)
#
# Purpose: This script automates the management of WireGuard VPN peers (clients).
# It simplifies the process of adding, removing, and listing peers, as well as
# generating all necessary configuration files and security keys.
#
# Requirements:
# - WireGuard must be installed and configured on the server
# - The script must be run with root privileges
# - The 'qrencode' package must be installed for QR code generation
#
# This script will:
# - Add, remove, or list WireGuard peers
# - Generate required security keys (private, public, and preshared)
# - Update the WireGuard interface (wg0) configuration
# - Create a folder for each peer with a .conf file and QR code for easy deployment
#
# ToDo: Implement rsync/sync of configs to a file server for easier access.

# Global Variables
# check if the config file is present - if not create the config file with base
# values to chow the users what global variables are needed

WIREGUARDDIR="/etc/wireguard/"

if [ -f "$WIREGUARDDIR/wg-manager.conf" ]; then
    if grep -q "GENERATED DEFAULTS" "./wg-manager.conf"; then
        echo ""
        echo "Error: The config file was not edited or the GENERATED DEFAULTS line was not removed."
        echo "Please edit the file and remove the GENERATED DEFAULTS line to use wg-manager."
        echo ""
        exit 1
    else
        source $WIREGUARDDIR/wg-manager.conf
    fi
else
    echo ""
    echo "Error: Configuration file not found."
    echo "A skeleton file has been created. Please edit the file to match your environment before running the script again."
    echo ""
    {
        echo "GENERATED DEFAULTS # Remove this entire line from this file to let wg-manager know that you changed the default values"
        echo 'DB_FILE="/etc/wireguard/peers.db"'
        echo 'CONFIG_FILE="/etc/wireguard/wg0.conf"'
        echo 'PEERS_DIR="/etc/wireguard/clients/"'
        echo 'IP_BASE="10.0.100"'
        echo 'NEXT_IP=2'
        echo 'ENDPOINT="x.x.x.x:51820"'
        echo 'SERVER_PUBLIC_KEY="YOUR KEY HERE"'
        echo 'ALLOWED_IPS="10.0.100.0/24,x.x.x.x"'
        echo 'DNS="x.x.x.x"'
        echo 'CONFFILE_NAME="office"'
    } > "$WIREGUARDDIR/wg-manager.conf"

    exit 1

fi


# Function to get the next available IP address
get_next_ip() {
    while grep -q "${IP_BASE}.${NEXT_IP}" "$DB_FILE"; do
        NEXT_IP=$((NEXT_IP + 1))
    done
    echo "${IP_BASE}.${NEXT_IP}"
}

# Function to check if a peer name is unique
check_name() {
    local name=$1
    if grep -q "$name" "$DB_FILE"; then
        return 0  # Name exists in DB
    else
        return 1  # Name does not exist in DB
    fi
}

# Function to add a new peer
add_peer() {
    local name="$1"
    local ip=$(get_next_ip)
    local peer_dir=$PEERS_DIR$name
    local peer_file=${peer_dir}/$CONFFILE_NAME.conf

    # Check if the peer name is unique
    if check_name "$name"; then
        echo ""
        echo "Error: The peer name '$name' is already in use."
        echo "Please use a different name or remove the existing peer."
        echo ""
        exit 1
    fi

    # Generate security keys
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)
    preshared_key=$(wg genkey)
    
    # Add peer to database
    echo "$name,$ip,$public_key" >> "$DB_FILE"
    
    # Add peer to WireGuard config
    {
        echo ""
        echo "# $name"
        echo "[Peer]"
        echo "PublicKey = $public_key"
        echo "PresharedKey = $preshared_key"
        echo "AllowedIPs = $ip/32"
    } >> "$CONFIG_FILE"
    
    # Generate peer configuration file
    mkdir -p $peer_dir
    {
        echo "# $name"
        echo "[Interface]"
        echo "Address = $ip/24"
        echo "PrivateKey = $private_key"
	   echo "DNS = $DNS"
        echo ""
        echo "[Peer]"
        echo "PublicKey = $SERVER_PUBLIC_KEY"
        echo "PresharedKey = $preshared_key"
        echo "AllowedIPs = $ALLOWED_IPS"
        echo "Endpoint = $ENDPOINT"
    } > "$peer_file"
    
    # Generate QR Code
    qrencode -t PNG -o $peer_dir/$CONFFILE_NAME.png < $peer_file

    echo ""
    echo "Success: Peer '$name' added with IP $ip"
    echo "Peer configuration file generated at: $peer_file"
    echo "QR Code for mobile setup:"
    qrencode -t ANSIUTF8 < $peer_file
    echo ""
}

# Function to remove a peer
remove_peer() {
    local name="$1"
    # Check if the peer exists before attempting to remove
    if ! check_name "$name"; then
        echo ""
        echo "Error: The peer '$name' does not exist."
        echo "Please check the peer name and try again."
        echo ""
        exit 1
    fi

    sed -i "/^$name,/d" "$DB_FILE"
    sed -i "/# $name/,/^\$/d" "$CONFIG_FILE"
    rm -r $PEERS_DIR$name
    echo ""
    echo "Success: Peer '$name' has been removed."
    echo "The peer's configuration directory has been deleted."
    echo ""
}

# Function to list all peers
list_peers() {
    echo ""
    echo "Current WireGuard Peers:"
    echo "========================"
    (echo "Name,IP Address,Public Key" && cat $DB_FILE) | column -t -s ',' | sed '1s/^/\n/'
    echo ""
}

# Function to map peers to pubkeys in wg show
list_connections() {
    # Read db and create an associative array
    local -A peer_names
    while IFS=',' read -r name ip pubkey; do
        peer_names[$pubkey]=$name
    done < $DB_FILE

    # Run wg show and process its output
    wg show | while read -r line; do
        if [[ $line =~ ^peer ]]; then
            pubkey=$(echo $line | awk '{print $2}')
            name=${peer_names[$pubkey]:-"Unknown"}
            echo "$line ($name)"
        else
            echo "$line"
        fi
    done
}

# Function to display connection status for peer passed to the script
search_peer() {
    local name="$1"
    # get the pubkey for the $name we are looking for
    local pubkey=$(grep -w -m 1 $name $DB_FILE | awk -F',' '{print $3'})
    # bail if the peer does not exist
    
    if [[ -z "$pubkey" ]]; then
        echo ""
        echo "Error: peer does not exist"
        echo "Please use this function with a exactly matching peername"
        echo ""
        exit 1
    fi

    # Get the peer block for the specified public key
    PEER_BLOCK=$(wg show | awk -v key="$pubkey" '
        BEGIN { found=0 }
        /^peer: / {
            if ($2 == key) {
                found=1
                print $0
            } else {
                found=0
            }
        }
        found && !/^peer: / { print $0 }
        found && /^$/ { exit }
    ')
    
    # print the peer block
    echo ""
    echo "$PEER_BLOCK"
    echo ""
}


# Function to display default settings
get_defaults(){
    echo ""
    echo "Current Default Settings:"
    echo "========================="
    echo "Peers database file: $DB_FILE"
    echo "WireGuard config file: $CONFIG_FILE"
    echo "Peer configs directory: $PEERS_DIR"
    echo "WireGuard subnet: $IP_BASE.0/24"
    echo "WireGuard server endpoint: $ENDPOINT"
    echo "Allowed IPs (client-side): $ALLOWED_IPS"
    echo "Peer config filename: $CONFFILE_NAME.conf"
    echo "QR code filename: $CONFFILE_NAME.png"
    echo ""
}

# Main script logic
case "$1" in
    add)
        add_peer "$2"
        ;;
    remove)
        remove_peer "$2"
        ;;
    list)
        list_peers
        ;;
    get_defaults)
        get_defaults
        ;;
    list_connections)
        list_connections
        ;;
    search_peer)
        search_peer "$2"
        ;;
    *)
        cat << EOF

WireGuard Peer Management Script
================================

This script simplifies the process of managing WireGuard VPN peers (clients).

Features:
---------
1. Add, remove, list or search WireGuard peers and their connection status
2. Automatically generate all necessary security keys
3. Update the WireGuard configuration (wg0 interface)
4. Create a separate folder for each peer, containing:
   - A ready-to-use .conf file for the client
   - A QR code for easy mobile device setup

Important Notes:
----------------
- This script uses predefined settings without prompting for input
- Peer removal is immediate and without confirmation
- Review the default settings (use 'get_defaults' command) before using

Usage:
------
$0 {add|remove|list|get_defaults|list_connections|search_peer} [peer_name]

Examples:
  Add a new peer:      $0 add N-ERL-019
  Remove a peer:       $0 remove N-ERL-019
  List all peers:      $0 list
  Show defaults:       $0 get_defaults
  List all connections $0 list_connections
  Search for a peer    $0 search_peer N-ERL-019

Caution: This script will make immediate changes. Use with care!

EOF
        exit 1
        ;;
esac

# Apply changes to WireGuard
wg syncconf wg0 <(wg-quick strip wg0)
