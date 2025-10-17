#!/bin/bash

# Function to format a byte as printable or \xYY
format_byte() {
    local byte=$1
    if [ $byte -lt 32 ] || [ $byte -eq 127 ] || [ $byte -eq 160 ] || [ $byte -eq 173 ] || [[ "129 131 136 141 143 144 157" =~ $byte ]]; then
        printf '\\x%02X' "$byte"
    else
        printf "\\$(printf '%03o' "$byte")"
    fi
}

# Read input
read -p "Enter text: " text
read -p "Enter password: " password

# Convert text and password to Windows-1250 bytes
text_bytes=($(echo -n "$text" | iconv -f UTF-8 -t CP1250 | xxd -p -c1 | sed 's/../0x&/'))
pwd_bytes=($(echo -n "$password" | iconv -f UTF-8 -t CP1250 | xxd -p -c1 | sed 's/../0x&/'))

len=${#text_bytes[@]}
pwd_len=${#pwd_bytes[@]}

# XOR each byte
output_bytes=()
for ((i=0;i<$len;i++)); do
    t=${text_bytes[i]}
    p=${pwd_bytes[i % pwd_len]}  # repeat password if shorter
    xor=$(( t ^ p ))
    output_bytes+=($xor)
done

# Print results
echo -n "Output Hex: "
for b in "${output_bytes[@]}"; do
    printf "%02X " "$b"
done
echo

echo -n "Output Binary: "
for b in "${output_bytes[@]}"; do
    printf "%08d " "$(echo "obase=2;$b" | bc)"
done
echo

echo -n "Output Text: "
for b in "${output_bytes[@]}"; do
    format_byte "$b"
done
echo