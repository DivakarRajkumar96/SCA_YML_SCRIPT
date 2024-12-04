# GitHub Repository Automation Script

This PowerShell script automates the process of creating new repositories in a GitHub organization, cloning existing repositories from provided URLs, and pushing their content to the newly created repositories. It also sets up a GitHub Actions workflow by copying a pre-existing YAML file into the repository's `.github/workflows` directory.

## Requirements

Before running the script, ensure you have the following prerequisites:

1. **PowerShell** (Windows, Linux, or macOS)
2. **Git** installed and available in the system's `PATH`
3. **GitHub Personal Access Token (PAT)** with the necessary permissions to create repositories and push content to them
4. **Excel File** containing the list of repositories to be cloned and migrated. The Excel file must have at least two columns: `Repo Name` and `Repo URL`.
5. **Workflow YAML File** (`semgrep.yml`) that defines the GitHub Actions workflow to be added to the new repositories.

## Usage

### 1. Set Up Your Environment

- Ensure you have the required tools installed:
    - **Git**: [Install Git](https://git-scm.com/downloads)
    - **PowerShell**: Pre-installed on Windows or can be installed on Linux/macOS.
    - **GitHub Personal Access Token (PAT)**: [Generate a PAT](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token).

### 2. Prepare Your Files

- **Excel File**: Create an Excel file with at least the following columns:
    - `Repo Name`: The name of the repository you want to create in GitHub.
    - `Repo URL`: The URL of the repository to be cloned (e.g., `https://github.com/username/repo-name`).

    Example Excel file (`test.xlsx`):

    | Repo Name  | Repo URL                             |
    |------------|--------------------------------------|
    | repo1      | https://github.com/user/repo1       |
    | repo2      | https://github.com/user/repo2       |

- **Workflow YAML File**: Create or download the GitHub Actions workflow file `semgrep.yml` and place it in the same directory as your Excel file. This file will be added to the `.github/workflows` directory of the new repositories.

### 3. Update the Script

- Update the following variables in the script:
    - `$excelFilePath`: The full path to the Excel file (e.g., `C:\path\to\test.xlsx`).
    - `$organization`: The name of your GitHub organization.
    - `$pat`: Your GitHub Personal Access Token (PAT).

### 4. Run the Script

1. Open a PowerShell window.
2. Run the script:

```powershell
.\CreateAndPushRepos.ps1
```

### 5. Verify the Repositories

After the script completes, visit the GitHub organization page to verify that the repositories have been created successfully, and the workflow file (`semgrep.yml`) has been added to the `.github/workflows` directory.

You should see:
- A list of newly created repositories in your GitHub organization.
- The `semgrep.yml` file located in the `.github/workflows` directory in each repository.

## What the Script Does

The script will:

1. **Create repositories in the specified GitHub organization**: The script uses the GitHub API to create a new repository for each entry in the provided Excel file.
2. **Clone the existing repositories**: The script clones each repository listed in the Excel file from the specified URL to a temporary local directory using Git.
3. **Push the contents to the newly created repositories**: After cloning the existing repositories, the script pushes the contents to the newly created repositories in your GitHub organization.
4. **Add the workflow file to each repository**: The script copies a specified GitHub Actions workflow YAML file (`semgrep.yml`) into the `.github/workflows` directory of each newly created repository.
