# XOR Encoding Script for Windows PowerShell (Windows-1250 compatible)

function Parse-InputString {
    param([string]$input)

    $resultBytes = New-Object System.Collections.Generic.List[byte]
    $i = 0
    while ($i -lt $input.Length) {
        if ($input[$i] -eq '\' -and ($i + 3) -lt $input.Length -and $input[$i+1] -eq 'x') {
            $hexStr = $input.Substring($i+2,2)
            if ($hexStr -match '^[0-9A-Fa-f]{2}$') {
                $byteVal = [Convert]::ToByte($hexStr,16)
                $resultBytes.Add($byteVal)
                $i += 4
                continue
            }
        }
        $char = $input[$i]
        $bytes = [System.Text.Encoding]::GetEncoding(1250).GetBytes($char)
        $resultBytes.AddRange($bytes)
        $i++
    }
    return $resultBytes.ToArray()
}

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
$textInput = Read-Host "Enter text (use \xNN for hex bytes)"
$passwordInput = Read-Host "Enter password (use \xNN for hex bytes)"

# Parse inputs to byte arrays
$textBytes = Parse-InputString $textInput
$passwordBytes = Parse-InputString $passwordInput

# Prepare arrays for output
$textHex = @()
$textBin = @()
$passwordHex = @()
$passwordBin = @()
$outputBytes = New-Object System.Collections.Generic.List[byte]
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

# XOR operation (password repeats if shorter)
for ($i = 0; $i -lt $textBytes.Length; $i++) {
    $pIndex = $i % $passwordBytes.Length
    $xorByte = $textBytes[$i] -bxor $passwordBytes[$pIndex]
    $outputBytes.Add([byte]$xorByte)
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