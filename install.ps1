[CmdletBinding()]
param(
  [switch]$Pi,
  [switch]$Codex,
  [switch]$Claude,
  [switch]$Unlink,
  [switch]$BackupExisting,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Arguments
)

$ErrorActionPreference = "Stop"
$CanonicalRoot = if ($env:DEV_SKILLS_ROOT) { $env:DEV_SKILLS_ROOT } else { Join-Path $HOME ".agents" }
$RepoUrl = if ($env:DEV_SKILLS_REPO_URL) { $env:DEV_SKILLS_REPO_URL } else { "git@github.com:Divarizky/dev-workflow-skills.git" }

# Parse all options ourselves so double-dash flags work consistently in
# PowerShell and shell scripts.
for ($Index = 0; $Index -lt $Arguments.Count; $Index++) {
  $Argument = $Arguments[$Index].ToLowerInvariant()
  switch ($Argument) {
    "--pi" { $Pi = $true }
    "--codex" { $Codex = $true }
    "--claude" { $Claude = $true }
    "--unlink" { $Unlink = $true }
    "--backup-existing" { $BackupExisting = $true }
    "--canonical-root" {
      if ($Index + 1 -ge $Arguments.Count) { throw "Nilai --canonical-root belum diberikan." }
      $Index++
      $CanonicalRoot = $Arguments[$Index]
    }
    "--repo-url" {
      if ($Index + 1 -ge $Arguments.Count) { throw "Nilai --repo-url belum diberikan." }
      $Index++
      $RepoUrl = $Arguments[$Index]
    }
    default { throw "Argumen tidak dikenal: $($Arguments[$Index])" }
  }
}

$Agents = @()
if ($Pi) { $Agents += "pi" }
if ($Codex) { $Agents += "codex" }
if ($Claude) { $Agents += "claude" }
if ($Agents.Count -eq 0) {
  throw "Pilih minimal satu agent: --Pi, --Codex, atau --Claude."
}

function Get-FullPath([string]$Path) {
  return [System.IO.Path]::GetFullPath($Path)
}

function Get-AgentSkillPath([string]$Agent) {
  switch ($Agent) {
    "pi" {
      $root = if ($env:PI_CODING_AGENT_DIR) { $env:PI_CODING_AGENT_DIR } else { Join-Path $HOME ".pi\agent" }
    }
    "codex" {
      $root = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
    }
    "claude" {
      $root = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
    }
  }
  return Join-Path $root "skills\dev"
}

function Test-ReparsePoint([string]$Path) {
  try {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    return (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
  } catch {
    return $false
  }
}

function Ensure-Canonical([string]$Root) {
  $root = Get-FullPath $Root
  if (-not (Test-Path -LiteralPath $root)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $root) | Out-Null
    Write-Host "Cloning canonical repository ke $root"
    git clone $RepoUrl $root
  } elseif (-not (Test-Path -LiteralPath (Join-Path $root ".git"))) {
    Write-Host "Memakai shared skills root yang sudah ada di $root (update Git dilewati)"
  } else {
    $dirty = git -C $root status --porcelain
    if ($dirty) {
      throw "$root memiliki perubahan lokal. Commit/stash dulu sebelum installer melakukan update."
    }
    Write-Host "Memperbarui canonical repository di $root"
    git -C $root pull --ff-only
  }

  $skill = Join-Path $root "skills\dev"
  if (-not (Test-Path -LiteralPath (Join-Path $skill "ask-me\SKILL.md"))) {
    throw "Canonical repository tidak memiliki skills\dev yang valid: $skill"
  }
  return @{ Root = $root; Skill = (Get-FullPath $skill) }
}

function Test-LinkTo([string]$Path, [string]$CanonicalSkill) {
  if (-not (Test-ReparsePoint $Path)) { return $false }
  try {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    foreach ($linkTarget in @($item.Target)) {
      if ($linkTarget -and ((Get-FullPath $linkTarget) -eq (Get-FullPath $CanonicalSkill))) {
        return $true
      }
    }
  } catch {}
  return $false
}

function Ensure-Link([string]$Agent, [string]$Target, [string]$CanonicalSkill) {
  $target = Get-FullPath $Target
  $parent = Split-Path -Parent $target
  New-Item -ItemType Directory -Force -Path $parent | Out-Null

  if (Test-LinkTo $target $CanonicalSkill) {
    Write-Host "[$Agent] sudah terhubung: $target"
    return
  }

  if ((Test-Path -LiteralPath $target -PathType Container -ErrorAction SilentlyContinue) -or (Test-ReparsePoint $target)) {
    if (-not $BackupExisting) {
      if (Test-ReparsePoint $target) {
        throw "[$Agent] target adalah link ke lokasi lain: $target. Gunakan --backup-existing untuk memindahkannya secara reversible."
      }
      throw "[$Agent] folder skill nyata sudah ada: $target. Gunakan --backup-existing untuk memindahkannya secara reversible."
    }

    $backup = "$target.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $target -Destination $backup
    Write-Host "[$Agent] target lama dipindahkan ke $backup"
  }

  New-Item -ItemType Junction -Path $target -Target $CanonicalSkill | Out-Null
  Write-Host "[$Agent] junction dibuat: $target -> $CanonicalSkill"
}

function Remove-Link([string]$Agent, [string]$Target, [string]$CanonicalSkill) {
  $target = Get-FullPath $Target
  if (-not (Test-ReparsePoint $target)) {
    if (Test-Path -LiteralPath $target) {
      Write-Warning "[$Agent] dilewati karena bukan link: $target"
    } else {
      Write-Host "[$Agent] tidak ada link: $target"
    }
    return
  }

  if (-not (Test-LinkTo $target $CanonicalSkill)) {
    Write-Warning "[$Agent] dilewati karena link tidak menunjuk ke canonical source: $target"
    return
  }

  Remove-Item -LiteralPath $target -Recurse -Force -Confirm:$false
  Write-Host "[$Agent] link dilepas: $target"
}

$canonical = Ensure-Canonical $CanonicalRoot
foreach ($Agent in $Agents) {
  $target = Get-AgentSkillPath $Agent
  if ($Unlink) {
    Remove-Link $Agent $target $canonical.Skill
  } else {
    Ensure-Link $Agent $target $canonical.Skill
  }
}

Write-Host "Selesai. Canonical source: $($canonical.Root)"
