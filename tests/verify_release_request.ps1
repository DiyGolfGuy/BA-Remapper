$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../scripts/release-request.ps1"
$base = @{ Ref = 'refs/heads/main'; Version = '5.1.2' }
$cases = @(
    @{ Name = 'ordinary main push builds only'; EventName = 'push'; Want = $false },
    @{ Name = 'manual build defaults to no publish'; EventName = 'workflow_dispatch'; Want = $false },
    @{ Name = 'manual exact version publishes'; EventName = 'workflow_dispatch'; ManualPublish = $true; ConfirmVersion = '5.1.2'; Want = $true },
    @{ Name = 'approved exact footer publishes'; EventName = 'push'; CommitMessage = "Release 5.1.2`n`nPublish-Remapper: 5.1.2"; Want = $true },
    @{ Name = 'footer is inert on a PR'; EventName = 'pull_request'; CommitMessage = 'Publish-Remapper: 5.1.2'; Want = $false },
    @{ Name = 'prose is not a publication footer'; EventName = 'push'; CommitMessage = 'Docs mention Publish-Remapper: 5.1.2'; Want = $false },
    @{ Name = 'future ordinary version builds only'; EventName = 'push'; Version = '5.1.3'; Want = $false },
    @{ Name = 'wrong footer version refused'; EventName = 'push'; CommitMessage = 'Publish-Remapper: 5.1.1'; Throws = $true },
    @{ Name = 'stale approval refused after version bump'; EventName = 'push'; Version = '5.1.3'; CommitMessage = 'Publish-Remapper: 5.1.2'; Throws = $true },
    @{ Name = 'development publication refused'; EventName = 'push'; Ref = 'refs/heads/dev/v5.1.2'; CommitMessage = 'Publish-Remapper: 5.1.2'; Throws = $true },
    @{ Name = 'manual missing version refused'; EventName = 'workflow_dispatch'; ManualPublish = $true; Throws = $true },
    @{ Name = 'manual wrong version refused'; EventName = 'workflow_dispatch'; ManualPublish = $true; ConfirmVersion = '5.1.1'; Throws = $true },
    @{ Name = 'manual development ref refused'; EventName = 'workflow_dispatch'; Ref = 'refs/heads/dev/v5.1.2'; ManualPublish = $true; ConfirmVersion = '5.1.2'; Throws = $true },
    @{ Name = 'duplicate footer refused'; EventName = 'push'; CommitMessage = "Publish-Remapper: 5.1.2`nPublish-Remapper: 5.1.2"; Throws = $true }
)
foreach ($case in $cases) {
    $argsForCase = $base.Clone()
    foreach ($key in $case.Keys) { if ($key -notin @('Name', 'Want', 'Throws')) { $argsForCase[$key] = $case[$key] } }
    $didThrow = $false
    try { $actual = Get-RemapperReleaseRequest @argsForCase } catch { $didThrow = $true }
    if ($case.Throws) {
        if (!$didThrow) { throw "FAIL: $($case.Name)" }
    } elseif ($didThrow -or $actual -ne $case.Want) { throw "FAIL: $($case.Name)" }
    Write-Host "PASS: $($case.Name)"
}
