# Publication is explicit and version-specific. Ordinary pushes only build.
# The owner must authorize a release before a maintainer adds the footer.
function Get-RemapperReleaseRequest {
    param(
        [string]$EventName,
        [string]$Ref,
        [string]$Version,
        [bool]$ManualPublish = $false,
        [string]$ConfirmVersion = '',
        [string]$CommitMessage = ''
    )
    if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid release version' }
    $requested = ''
    if ($EventName -eq 'workflow_dispatch' -and $ManualPublish) {
        $requested = $ConfirmVersion
        if (!$requested) { throw 'Confirm the exact version before publication' }
    } elseif ($EventName -eq 'push') {
        $markers = [regex]::Matches($CommitMessage, '(?m)^Publish-Remapper: ([0-9]+\.[0-9]+\.[0-9]+)\r?$')
        if ($markers.Count -gt 1) { throw 'Only one publication footer is allowed' }
        if ($markers.Count -eq 1) { $requested = $markers[0].Groups[1].Value }
    }
    if (!$requested) { return $false }
    if ($Ref -cne 'refs/heads/main') { throw 'Public releases must use main' }
    if ($requested -cne $Version) { throw 'Publication request must match the exact app version' }
    return $true
}
