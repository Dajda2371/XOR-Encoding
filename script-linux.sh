#!/bin/bash
# XOR Encoding Script (Windows-1250 compatible, supports \xNN input)

# Function to format byte as printable character or \xYY
format_cp1250_byte() {
    local b=$1
    if [ $b -lt 32 ] || [ $b -eq 127 ] || [ $b -eq 160 ] || [ $b -eq 173 ] || [[ "129 131 136 144 157" =~ $b ]]; then
        printf "\\x%02X" "$b"
        return
    fi
    # Try decoding using Windows-1250
    local char
    char=$(printf "\\%03o" "$b" | iconv -f CP1250 -t UTF-8 2>/dev/null)
    if [[ -n "$char" && "$char" =~ [[:print:]] ]]; then
        printf "%s" "$char"
    else
        printf "\\x%02X" "$b"
    fi
}

# Function to parse input, converting \xNN to raw bytes
parse_hex_input() {
    local s="$1"
    local result=()
    local i=0
    while [ $i -lt ${#s} ]; do
        local ch="${s:$i:1}"
        if [ "$ch" = "\\" ] && [ "${s:$((i+1)):1}" = "x" ]; then
            local hex="${s:$((i+2)):2}"
            if [[ "$hex" =~ ^[0-9A-Fa-f]{2}$ ]]; then
                result+=($((16#$hex)))
                ((i+=4))
                continue
            fi
        fi
        # Encode regular characters to CP1250
        local byte=$(echo -n "$ch" | iconv -f UTF-8 -t CP1250 | xxd -p)
        result+=($((16#$byte)))
        ((i++))
    done
    echo "${result[@]}"
}

# ---- Input ----
if [ $# -ge 2 ]; then
    text="$1"
    password="$2"
else
    read -p "Enter text: " text
    read -p "Enter password: " password
fi

# Parse both text and password
text_bytes=($(parse_hex_input "$text"))
password_bytes=($(parse_hex_input "$password"))

len_text=${#text_bytes[@]}
len_pass=${#password_bytes[@]}

# ---- Build representations ----
text_hexadecimals=()
text_binaries=()
password_hexadecimals=()
password_binaries=()

for b in "${text_bytes[@]}"; do
    text_hexadecimals+=($(printf "%02X" "$b"))
    text_binaries+=($(echo "obase=2;$b" | bc | awk '{printf "%08d", $0}'))
done

for ((i=0; i<$len_text; i++)); do
    b=${password_bytes[$((i % len_pass))]}
    password_hexadecimals+=($(printf "%02X" "$b"))
    password_binaries+=($(echo "obase=2;$b" | bc | awk '{printf "%08d", $0}'))
done

# ---- XOR bits ----
bit_string=""
for ((i=0; i<$len_text; i++)); do
    t=${text_bytes[$i]}
    p=${password_bytes[$((i % len_pass))]}
    xor_val=$((t ^ p))
    bit_string+=$(printf "%08d" "$(echo "obase=2;$xor_val" | bc)")
done

# ---- Group into bytes ----
output_binaries=()
for ((i=0; i<${#bit_string}; i+=8)); do
    output_binaries+=("${bit_string:$i:8}")
done

# ---- Convert to integers and hex ----
output_integers=()
output_hexadecimals=()
for b in "${output_binaries[@]}"; do
    val=$((2#$b))
    output_integers+=($val)
    output_hexadecimals+=($(printf "%02X" "$val"))
done

# ---- Output ----
echo "Hexadecimals: ${text_hexadecimals[*]}"
echo "Binaries: ${text_binaries[*]}"
echo "Password Hexadecimals: ${password_hexadecimals[*]}"
echo "Password Binary: ${password_binaries[*]}"
echo "Output Binaries: ${output_binaries[*]}"
echo "Output Hexadecimals: ${output_hexadecimals[*]}"

# Output text with CP1250 formatting
echo -n "Output Text: "
for b in "${output_integers[@]}"; do
    format_cp1250_byte "$b"
done
echo