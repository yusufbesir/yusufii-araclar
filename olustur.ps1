# Builds the Word log from kayit.csv. Keep this file saved as UTF-8 *with BOM*:
# Windows PowerShell 5.1 reads BOM-less scripts as ANSI and mangles Turkish paths.
param(
    [string]$Csv = (Join-Path $PSScriptRoot 'kayit.csv'),
    [string]$Out = (Join-Path $env:USERPROFILE ([regex]::Unescape('Desktop\\myb masaüstü\\CLAUDE İŞLEM KAYDI.docx')))
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression

function U([string]$s) { [regex]::Unescape($s) }
function X([string]$s) { [System.Security.SecurityElement]::Escape($s) }

function Run([string]$text, [bool]$bold = $false, [int]$size = 18, [string]$color = '') {
    $rpr = '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'
    if ($bold) { $rpr += '<w:b/>' }
    if ($color) { $rpr += "<w:color w:val=`"$color`"/>" }
    $rpr += "<w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/>"
    "<w:r><w:rPr>$rpr</w:rPr><w:t xml:space=`"preserve`">$(X $text)</w:t></w:r>"
}
function Para([string]$runs, [string]$align = 'left', [int]$after = 0) {
    "<w:p><w:pPr><w:spacing w:before=`"0`" w:after=`"$after`"/><w:jc w:val=`"$align`"/></w:pPr>$runs</w:p>"
}
function Cell([int]$w, [string]$text, [bool]$bold = $false, [string]$fill = '', [string]$align = 'left', [string]$color = '') {
    $shd = if ($fill) { "<w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"$fill`"/>" } else { '' }
    "<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/>$shd<w:vAlign w:val=`"center`"/></w:tcPr>$(Para (Run $text $bold 18 $color) $align)</w:tc>"
}

$rows = Import-Csv -Path $Csv -Delimiter ';' -Encoding UTF8
$widths = 700, 1400, 2100, 7438, 3200   # sums to 14838 = landscape A4 minus 1000 margins
$grid = ($widths | ForEach-Object { "<w:gridCol w:w=`"$_`"/>" }) -join ''
$hdrNames = '#', 'Tarih', (U 'Işlem türü'), (U 'Yapılan işlem'), (U 'Sonuç / not')

$hdr = '<w:tr><w:trPr><w:tblHeader/></w:trPr>'
for ($i = 0; $i -lt 5; $i++) { $hdr += Cell $widths[$i] $hdrNames[$i] $true '1F3864' 'left' 'FFFFFF' }
$hdr += '</w:tr>'

$body = ''
$n = 0
foreach ($r in $rows) {
    $n++
    $fill = if ($r.Tur -like 'Silme*') { 'FDE9E7' } elseif ($n % 2 -eq 0) { 'F2F5F9' } else { '' }
    $body += '<w:tr><w:trPr><w:cantSplit/></w:trPr>'
    $body += Cell $widths[0] "$n" $false $fill 'center'
    $body += Cell $widths[1] $r.Tarih $false $fill
    $body += Cell $widths[2] $r.Tur $true $fill
    $body += Cell $widths[3] $r.Islem $false $fill
    $body += Cell $widths[4] $r.Sonuc $false $fill
    $body += '</w:tr>'
}

$b = '<w:top w:val="single" w:sz="4" w:color="BFBFBF"/><w:left w:val="single" w:sz="4" w:color="BFBFBF"/><w:bottom w:val="single" w:sz="4" w:color="BFBFBF"/><w:right w:val="single" w:sz="4" w:color="BFBFBF"/><w:insideH w:val="single" w:sz="4" w:color="BFBFBF"/><w:insideV w:val="single" w:sz="4" w:color="BFBFBF"/>'
$table = "<w:tbl><w:tblPr><w:tblW w:w=`"14838`" w:type=`"dxa`"/><w:tblBorders>$b</w:tblBorders><w:tblLayout w:type=`"fixed`"/><w:tblCellMar><w:top w:w=`"60`" w:type=`"dxa`"/><w:left w:w=`"100`" w:type=`"dxa`"/><w:bottom w:w=`"60`" w:type=`"dxa`"/><w:right w:w=`"100`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr><w:tblGrid>$grid</w:tblGrid>$hdr$body</w:tbl>"

$updated = Get-Date -Format 'dd.MM.yyyy HH:mm'
$title = Para (Run (U 'Claude İşlem Kaydı') $true 36 '1F3864') 'left' 60
$sub1 = Para (Run (U 'Claude tarafından bilgisayarda yapılan tüm işlemlerin sıralı kaydı. Her yeni işlem sonuna eklenir.') $false 20 '595959') 'left' 40
$sub2 = Para (Run ((U 'Toplam kayıt: ') + $n + (U '   ·   Son güncelleme: ') + $updated + (U '   ·   Kırmızı satırlar silme işlemidir.')) $false 18 '7F7F7F') 'left' 200

$sect = '<w:sectPr><w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/><w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000" w:header="500" w:footer="500" w:gutter="0"/></w:sectPr>'
$doc = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + $title + $sub1 + $sub2 + $table + '<w:p/>' + $sect + '</w:body></w:document>'

$ct = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>'
$rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'

$tmp = "$Out.tmp"
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp }
$fs = [System.IO.File]::Open($tmp, 'CreateNew')
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($e in @(@('[Content_Types].xml', $ct), @('_rels/.rels', $rels), @('word/document.xml', $doc))) {
    $w = New-Object System.IO.StreamWriter($zip.CreateEntry($e[0]).Open(), $utf8)
    $w.Write($e[1]); $w.Close()
}
$zip.Dispose(); $fs.Close()
Move-Item -LiteralPath $tmp -Destination $Out -Force
"OK: $n kayit -> $Out"
