n = 0

def format_cp1250_byte(b):
    undefined_bytes = {0x81, 0x83, 0x88, 0x90, 0x98}
    if b < 32 or b == 0x7F or b == 0xA0 or b == 0xAD or b in undefined_bytes:
        return f"\\x{b:02X}"
    try:
        char = bytes([b]).decode('cp1250')
        # Check if character is printable and not a control character
        if char.isprintable() and char not in '\u200b\u200c\u200d\u200e\u200f':
            return char
        else:
            return f"\\x{b:02X}"
    except:
        return f"\\x{b:02X}"

def parse_hex_input(s):
    result = bytearray()
    i = 0
    while i < len(s):
        if i + 3 < len(s) and s[i] == '\\' and s[i+1] == 'x':
            try:
                byte_val = int(s[i+2:i+4], 16)
                result.append(byte_val)
                i += 4
                continue
            except ValueError:
                pass
        result.extend(s[i].encode('cp1250', errors='ignore'))
        i += 1
    return bytes(result)

text = input("Enter text: ")
password = input("Enter password: ")

text_bytes = parse_hex_input(text)
password_bytes = parse_hex_input(password)

text_integers = []
text_hexadecimals = []
text_binaries = []

password_integers = []
password_hexadecimals = []
password_binaries = []

output_binaries = []
bit_string = []
byte_string = []
output_hexadecimals = []
output_integers = []

for b in text_bytes:
    text_integer = b
    text_hexadecimal = format(text_integer, '02X')
    text_binary = format(text_integer, '08b')
    
    text_integers.append(text_integer)
    text_hexadecimals.append(text_hexadecimal)
    text_binaries.append(text_binary)

for b in password_bytes:
    password_integer = b
    password_hexadecimal = format(password_integer, '02X')
    password_binary = format(password_integer, '08b')
    
    password_integers.append(password_integer)
    password_hexadecimals.append(password_hexadecimal)
    password_binaries.append(password_binary)

for i in range(min(len(text_binaries), len(password_binaries))):
    for bit in range(8):
        if text_binaries[i][n] == password_binaries[i][n]:
            bit_string.append("0")
        else:
            bit_string.append("1")

        if n >= 7:
            n = 0
        else:
            n += 1

# Group bits into bytes
byte_string = ''.join(bit_string)
output_binaries = [byte_string[i:i+8] for i in range(0, len(byte_string), 8)]

# Convert bytes to integers and hexadecimals
output_integers = [int(b, 2) for b in output_binaries]
output_hexadecimals = [format(x, '02X') for x in output_integers]

# print("Integers:", text_integers)
print("Hexadecimals:", text_hexadecimals)
print("Binaries:", text_binaries)

# print("Password Integers:", password_integers)
print("Password Hexadecimals:", password_hexadecimals)
print("Password Binary:", password_binaries)

print("Output Binaries:", output_binaries)
print("Output Hexadecimals:", output_hexadecimals)
# print("Output Integers:", output_integers)

print("Output Text:", ''.join(format_cp1250_byte(b) for b in output_integers))