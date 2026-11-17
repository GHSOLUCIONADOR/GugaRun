# Guga Run - servidor local do totem (nao precisa de internet nem de instalar nada)
# Serve o jogo em http://localhost:8787/ e grava o ranking em arquivo, com varios backups.
$ErrorActionPreference = 'Continue'
$Raiz   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Jogo   = Join-Path $Raiz 'jogo'
$Dados  = Join-Path $Raiz 'dados'
$Bkp    = Join-Path $Dados 'backups'
$Main   = Join-Path $Dados 'ranking.json'
$Copia  = Join-Path $Dados 'ranking-copia.json'
$Hist   = Join-Path $Dados 'historico-partidas.csv'
$Log    = Join-Path $Dados 'servidor.log'
New-Item -ItemType Directory -Force -Path $Dados, $Bkp | Out-Null
$Utf8 = New-Object System.Text.UTF8Encoding($false)
function LogMsg($m){ try{ [IO.File]::AppendAllText($Log, ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $m + "`r`n"), $Utf8) }catch{} }

function Ler-Arquivo($p){
  if(-not (Test-Path $p)){ return $null }
  try{ $t = [IO.File]::ReadAllText($p, $Utf8); if(-not $t.Trim()){ return $null }; $j = ConvertFrom-Json $t; $a = @($j | ForEach-Object { $_ } | Where-Object { $_ -and $_.id }); return ,$a }catch{ LogMsg "arquivo invalido: $p"; return $null }
}
# Le o ranking: arquivo principal; se estiver corrompido, a copia; se nao, o backup mais recente.
function Ler-Ranking(){
  foreach($p in @($Main, $Copia)){ $r = Ler-Arquivo $p; if($null -ne $r){ return ,$r } }
  $ult = Get-ChildItem $Bkp -Filter 'ranking-*.json' -ErrorAction SilentlyContinue | Sort-Object Name -Descending
  foreach($f in $ult){ $r = Ler-Arquivo $f.FullName; if($null -ne $r){ LogMsg "restaurado do backup $($f.Name)"; return ,$r } }
  return ,@()
}
function Gravar-Seguro($p, $txt){
  $tmp = "$p.tmp"
  [IO.File]::WriteAllText($tmp, $txt, $Utf8)
  Move-Item -Force $tmp $p
}
function Salvar-Ranking($lista){
  $ord = @($lista | Sort-Object -Property @{Expression={[int]$_.s};Descending=$true}, @{Expression={[int]$_.ms};Descending=$true})
  $txt = ConvertTo-Json -InputObject $ord -Depth 4 -Compress
  if($ord.Count -eq 1){ $txt = '[' + (ConvertTo-Json -InputObject $ord[0] -Depth 4 -Compress) + ']' }
  Gravar-Seguro $Main $txt
  Gravar-Seguro $Copia $txt
  [IO.File]::WriteAllText((Join-Path $Bkp ('ranking-' + (Get-Date).ToString('yyyyMMdd-HHmmss-fff') + '.json')), $txt, $Utf8)
  return $txt
}
if(-not (Test-Path $Hist)){ [IO.File]::WriteAllText($Hist, "data_hora;nome;pontos;tempo_ms;caixas;id`r`n", $Utf8) }

$Mime = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript'; '.css'='text/css'; '.png'='image/png'; '.json'='application/json'; '.ttf'='font/ttf'; '.ico'='image/x-icon' }
$L = New-Object System.Net.HttpListener
$L.Prefixes.Add('http://localhost:8787/')
try{ $L.Start() }catch{ LogMsg "nao consegui abrir a porta 8787: $_"; exit 1 }
LogMsg 'servidor iniciado'

while($L.IsListening){
  try{
    $c = $L.GetContext(); $q = $c.Request; $res = $c.Response
    $path = $q.Url.AbsolutePath
    $out = $null; $type = 'application/json'; $code = 200
    if($path -eq '/api/ranking' -and $q.HttpMethod -eq 'GET'){
      $r = Ler-Ranking; $r = @($r)
      $out = if($r.Count -eq 0){'[]'}elseif($r.Count -eq 1){'[' + (ConvertTo-Json -InputObject $r[0] -Depth 4 -Compress) + ']'}else{ConvertTo-Json -InputObject $r -Depth 4 -Compress}
    }
    elseif($path -eq '/api/entry' -and $q.HttpMethod -eq 'POST'){
      $sr = New-Object IO.StreamReader($q.InputStream, $Utf8); $body = $sr.ReadToEnd(); $sr.Close()
      $e = ConvertFrom-Json $body
      if(-not $e.id){ throw 'entrada sem id' }
      $nome = ([string]$e.n) -replace '[^A-Za-z0-9 ]',''
      $entrada = [pscustomobject]@{ id=[string]$e.id; n=$nome.Substring(0,[Math]::Min(10,$nome.Length)); s=[int]$e.s; ms=[int]$e.ms; b=[int]$e.b }
      $r = Ler-Ranking; $r = @($r)
      if(-not ($r | Where-Object { $_.id -eq $entrada.id })){
        $r += $entrada
        [IO.File]::AppendAllText($Hist, ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ";$($entrada.n);$($entrada.s);$($entrada.ms);$($entrada.b);$($entrada.id)`r`n"), $Utf8)
        Salvar-Ranking $r | Out-Null
        LogMsg "nova partida: $($entrada.n) $($entrada.s)"
      }
      $out = '{"ok":true}'
    }
    else{
      $rel = if($path -eq '/'){'index.html'}else{ [Uri]::UnescapeDataString($path.TrimStart('/')) }
      $file = [IO.Path]::GetFullPath((Join-Path $Jogo $rel))
      if($file.StartsWith($Jogo) -and (Test-Path $file -PathType Leaf)){
        $bytes = [IO.File]::ReadAllBytes($file); $ext = [IO.Path]::GetExtension($file).ToLower()
        $type = if($Mime[$ext]){$Mime[$ext]}else{'application/octet-stream'}
        $res.ContentType = $type; $res.Headers.Add('Cache-Control','no-store'); $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes,0,$bytes.Length); $res.Close(); continue
      } else { $code = 404; $out = '{"erro":"nao encontrado"}' }
    }
    $b = $Utf8.GetBytes($out)
    $res.StatusCode = $code; $res.ContentType = $type; $res.Headers.Add('Cache-Control','no-store')
    $res.ContentLength64 = $b.Length; $res.OutputStream.Write($b,0,$b.Length); $res.Close()
  }catch{
    LogMsg "erro: $_"
    try{ $res.StatusCode = 500; $res.Close() }catch{}
  }
}
