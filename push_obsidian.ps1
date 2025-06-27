# Change this to the path of your Obsidian vault
$repoPath = "C:\Users\mahir\Desktop\PrepNotes"

# Optional: Change to the repo directory
Set-Location $repoPath

# Add all changes
git add .

# Commit with timestamp message (only if there are changes)
if (-not [string]::IsNullOrWhiteSpace((git status --porcelain))) {
    $commitMessage = "Auto-commit on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git commit -m "$commitMessage"
    git push origin main
}

