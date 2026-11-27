param(
    [string]$ModelPath = 'F:\OpenTPU\models\Qwen3.5-4B',
    [ValidateSet('isa', 'board', 'board-sim', 'bend')]
    [string]$Backend = 'isa',
    [ValidateRange(1024, 65535)]
    [int]$Port = 8765,
    [ValidateRange(1, 262144)]
    [int]$Context = 512,
    [ValidateSet('auto', 'fp4', 'nvfp4', 'int4', 'int8')]
    [string]$WeightFormat = 'auto',
    [ValidateSet('fp4', 'nvfp4', 'int4', 'int8')]
    [string]$HeadFormat,
    [string]$PoolPath,
    [ValidateRange(0, 1024)]
    [int]$ExpertSlots = 0,
    [string]$Device,
    [string]$ImageCachePath,
    [string]$Distro = 'OpenTPU-Ubuntu',
    [string]$WslUser = 'opentpu',
    [string]$OpenTPUSource = '/opt/opentpu/OpenTPU',
    [string]$Python = '/opt/opentpu/venv/bin/python',
    [switch]$EnablePromptRuns
)

$ErrorActionPreference = 'Stop'
$wsl = @('-d', $Distro, '-u', $WslUser)

function Convert-ToWslPath([string]$Path) {
    $localPath = (Resolve-Path -LiteralPath $Path).Path.Replace('\', '/')
    $linuxPath = & wsl.exe @wsl --exec wslpath -a -u $localPath
    if ($LASTEXITCODE -ne 0 -or -not $linuxPath) {
        throw "WSL could not map $Path."
    }
    return $linuxPath
}

$model = Convert-ToWslPath $ModelPath
$server = Convert-ToWslPath (Join-Path $PSScriptRoot 'server.py')
$options = @('--backend', $Backend, '--model', $model, '--host', '127.0.0.1', '--port', "$Port",
    '--cap', "$Context", '--wformat', $WeightFormat, '--slots', '1', '--max-running', '1',
    '--max-queue', '4', '--kv-ram-gb', '0.5')

if ($HeadFormat) { $options += @('--head-format', $HeadFormat) }
if ($PoolPath) { $options += @('--pool', (Convert-ToWslPath $PoolPath)) }
if ($ExpertSlots) { $options += @('--experts', "$ExpertSlots") }
if ($Device) { $options += @('--dev', $Device) }
if (-not $EnablePromptRuns) { $options += '--no-prompt-runs' }

$environment = @('HF_HUB_OFFLINE=1', 'TRANSFORMERS_OFFLINE=1', 'OMP_NUM_THREADS=4',
    'OPENBLAS_NUM_THREADS=4', 'MKL_NUM_THREADS=4', 'TOKENIZERS_PARALLELISM=false', 'PYTHONUNBUFFERED=1')
if ($ImageCachePath) {
    $environment += "OTPU_IMG_CACHE=$(Convert-ToWslPath $ImageCachePath)"
}

Write-Host "Open http://127.0.0.1:$Port/chat when the server is ready. Press Ctrl+C to stop."
& wsl.exe @wsl --cd $OpenTPUSource --exec env @environment $Python $server @options
exit $LASTEXITCODE
