#!/bin/bash


# Check if the key_directory variable is set
if [ -z "$key_directory" ]; then
  echo "Error: key_directory is not set."
  echo "Example usage  key_directory=~/key_directory bash update_authorized_keys.bash "
  echo "Example usage with exported env variable "
  echo "export key_directory=~/key_directory"
  echo "bash update_authorized_keys.bash"
  exit 1
fi


# Check if ~/.ssh directory exists, create it if it doesn't
if [ ! -d "$HOME/.ssh" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
fi

# Path to the authorized_keys file
AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

# Define mapfile function if it doesn't exist
if ! command -v mapfile > /dev/null; then
  mapfile() {
    local -n arr=$2
    while IFS= read -r line; do
      arr+=("$line")
    done < "$1"
  }
fi

# Check if the authorized_keys file exists
if [ ! -f "$AUTHORIZED_KEYS" ]; then
  touch "$AUTHORIZED_KEYS"
  chmod 600 "$AUTHORIZED_KEYS"
  # Add all public keys from key_directory to the authorized_keys file
  cat "$key_directory"/*.pub >> "$AUTHORIZED_KEYS"
else
  # Read all current keys in authorized_keys into an array
  mapfile -t CURRENT_KEYS < "$AUTHORIZED_KEYS"

  # Read all new keys from key_directory into an array
  mapfile -t NEW_KEYS < <(cat "$key_directory"/*.pub)

  # Remove all keys from authorized_keys that are no longer in key_directory
  for current_key in "${CURRENT_KEYS[@]}"; do
    if [[ ! " ${NEW_KEYS[*]} " =~ $current_key ]]; then
      sed -i "\|$current_key|d" "$AUTHORIZED_KEYS"
    fi
  done

  # Add any new keys from key_directory that are not in authorized_keys
  for new_key in "${NEW_KEYS[@]}"; do
    if ! grep -qF "$new_key" "$AUTHORIZED_KEYS"; then
      echo "$new_key" >> "$AUTHORIZED_KEYS"
    fi
  done
fi

echo "SSH keys have been updated."
