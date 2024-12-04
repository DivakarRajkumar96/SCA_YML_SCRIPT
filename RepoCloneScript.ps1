# Define the path to the Excel file
$excelFilePath = "PathToFile\test.xlsx"

# Define the GitHub organization and PAT
$organization = "OrgName"
$pat = "GitHubToken"

# Define the GitHub API URL for creating a repository
$githubApiUrl = "https://api.github.com/orgs/$organization/repos"

# Define a temporary directory for cloning repositories
$tempDir = "$env:TEMP\github-repos"

# Ensure the temporary directory exists
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory | Out-Null
}

# Define the path for the workflow YAML file (relative to the Excel file path)
$workflowYamlFilePath = Join-Path -Path (Split-Path -Path $excelFilePath -Parent) -ChildPath "semgrep.yml"

# Check if the workflow YAML file exists
if (-not (Test-Path -Path $workflowYamlFilePath)) {
    Write-Output "Workflow YAML file not found at $workflowYamlFilePath"
    exit
}

# Read the Excel file
$repos = Import-Excel -Path $excelFilePath

# Iterate over each row in the Excel file
foreach ($repo in $repos) {
    $repoName = $repo."Repo Name"
    $repoUrl = $repo."Repo URL"

    # Validate repoName
    if ([string]::IsNullOrEmpty($repoName)) {
        Write-Output "Repo Name is empty or null. Skipping."
        continue
    }

    # Strip any leading or trailing whitespace
    $repoName = $repoName.Trim()

    # Replace any slashes in the repository name with hyphens or another suitable character
    $safeRepoName = $repoName -replace '/', '-'

    # Validate repository name
    if ($safeRepoName.Length -lt 1 -or $safeRepoName.Length -gt 100 -or $safeRepoName -match '[^a-zA-Z0-9-_]') {
        Write-Output "Invalid repository name: $safeRepoName"
        continue
    }

    # Create a JSON payload for the API request
    $payload = @{
        name = $safeRepoName
        description = "Repository for $repoName"
        homepage = $repoUrl
        private = $true # Set to $false if the repository should be public
    } | ConvertTo-Json -Compress

    # Define the headers, including the authorization token
    $headers = @{
        Authorization = "Bearer $pat"
        Accept = "application/vnd.github.v3+json"
        UserAgent = "PowerShell"
    }

    # Make the API request to create the repository
    try {
        $response = Invoke-RestMethod -Uri $githubApiUrl -Method Post -Headers $headers -Body $payload -ErrorAction Stop
        Write-Output "Successfully created repository: $safeRepoName"

        # Define the local clone directory
        $localCloneDir = "$tempDir\$safeRepoName"

        # Clone the existing repository to the local directory
        Write-Output "Cloning repository from $repoUrl to $localCloneDir..."
        git clone $repoUrl $localCloneDir 2>&1 | Write-Output

        # Verify the cloning process
        if (-not (Test-Path -Path $localCloneDir)) {
            Write-Output "Failed to clone repository: $repoUrl"
            continue
        }

        # Change to the local clone directory
        Set-Location -Path $localCloneDir

        # Add the new remote repository
        Write-Output "Adding new remote repository..."
        git remote add new-origin "https://github.com/$organization/$safeRepoName.git" 2>&1 | Write-Output

        # Push the contents to the new repository
        Write-Output "Pushing contents to new repository..."
        git push new-origin main 2>&1 | Write-Output

        # Create .github/workflows directory
        $workflowsDir = ".github\workflows"
        if (-not (Test-Path -Path $workflowsDir)) {
            Write-Output "Creating workflows directory..."
            New-Item -Path $workflowsDir -ItemType Directory -Force | Out-Null
        }

        # Copy the workflow YAML file into the repository
        $destinationYamlPath = Join-Path -Path $workflowsDir -ChildPath "semgrep.yml"
        Write-Output "Copying workflow YAML file to $destinationYamlPath..."
        Copy-Item -Path $workflowYamlFilePath -Destination $destinationYamlPath -Force

        # Add, commit, and push changes
        Write-Output "Committing and pushing workflow file..."
        git add $destinationYamlPath
        git commit -m "Add Semgrep GitHub Actions workflow"
        git push new-origin main

        # Clean up by removing the local clone directory
        Set-Location -Path $tempDir
        Remove-Item -Path $localCloneDir -Recurse -Force -ErrorAction SilentlyContinue

    } catch {
        Write-Output "Failed to create or manage repository: $safeRepoName"
        Write-Output "Error details: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $responseStream = $_.Exception.Response.GetResponseStream()
            if ($responseStream) {
                $reader = New-Object System.IO.StreamReader($responseStream)
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
                Write-Output "Response Content: $responseBody"
            }
        }
    }
}
