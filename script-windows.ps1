# Helper function to format bytes like Python's format_cp1250_byte
function Format-CP1250Byte {
    param([byte]$b)

    $undefinedBytes = 0x81,0x83,0x88,0x8D,0x8F,0x90,0x9D
    if ($b -lt 32 -or $b -eq 0x7F -or $b -eq 0xA0 -or $b -eq 0xAD -or $undefinedBytes -contains $b) {
        return "\x{0:X2}" -f $b
    }

    try {
        $char = [System.Text.Encoding]::GetEncoding(1250).GetString(@($b))
        if ($char -match '\p{C}') { return "\x{0:X2}" -f $b }
        return $char
    } catch {
        return "\x{0:X2}" -f $b
    }
}

# Read text and password
$text = Read-Host "Enter text"
$password = Read-Host "Enter password"

# Encode to Windows-1250 bytes
$textBytes = [System.Text.Encoding]::GetEncoding(1250).GetBytes($text)
$passwordBytes = [System.Text.Encoding]::GetEncoding(1250).GetBytes($password)

# Prepare arrays
$textHex = @()
$textBin = @()
$passwordHex = @()
$passwordBin = @()
$outputBytes = @()
$outputHex = @()
$outputBin = @()

# Convert input bytes to hex and binary
foreach ($b in $textBytes) {
    $textHex += "{0:X2}" -f $b
    $textBin += [Convert]::ToString($b,2).PadLeft(8,'0')
}
foreach ($b in $passwordBytes) {
    $passwordHex += "{0:X2}" -f $b
    $passwordBin += [Convert]::ToString($b,2).PadLeft(8,'0')
}

# XOR operation (byte by byte)
$minLen = [Math]::Min($textBytes.Length, $passwordBytes.Length)
for ($i=0; $i -lt $minLen; $i++) {
    $xorByte = $textBytes[$i] -bxor $passwordBytes[$i]
    $outputBytes += [byte]$xorByte
    $outputHex += "{0:X2}" -f $xorByte
    $outputBin += [Convert]::ToString($xorByte,2).PadLeft(8,'0')
}

# Print results
Write-Host "Text Hex: $($textHex -join ' ')"
Write-Host "Text Bin: $($textBin -join ' ')"
Write-Host "Password Hex: $($passwordHex -join ' ')"
Write-Host "Password Bin: $($passwordBin -join ' ')"
Write-Host "Output Hex: $($outputHex -join ' ')"
Write-Host "Output Bin: $($outputBin -join ' ')"

# Format output text with control characters
$outputText = ($outputBytes | ForEach-Object { Format-CP1250Byte $_ }) -join ''
Write-Host "Output Text: $outputText"