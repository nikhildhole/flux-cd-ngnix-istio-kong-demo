# Flux CD Bootstrap Script for Minikube
# This script helps bootstrap Flux CD to watch the minikube branch

Write-Host "=== Flux CD Bootstrap Helper ===" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check if kubectl is available
try {
    kubectl version --client --short 2>&1 | Out-Null
    Write-Host "✓ kubectl is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ kubectl is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if flux is available
try {
    flux version --client 2>&1 | Out-Null
    Write-Host "✓ Flux CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Flux CLI is not installed" -ForegroundColor Red
    Write-Host "Install Flux CLI: https://fluxcd.io/flux/installation/" -ForegroundColor Yellow
    exit 1
}

# Check if minikube is running
try {
    $minikubeStatus = minikube status 2>&1
    if ($minikubeStatus -match "Running") {
        Write-Host "✓ Minikube is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Minikube is not running" -ForegroundColor Red
        Write-Host "Start Minikube with: minikube start --cpus=4 --memory=8192" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Minikube is not installed or not running" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Flux CD Bootstrap Options ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Choose your Git provider:" -ForegroundColor Yellow
Write-Host "1. GitHub"
Write-Host "2. GitLab"
Write-Host "3. Generic Git Repository"
Write-Host ""

$choice = Read-Host "Enter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=== GitHub Bootstrap ===" -ForegroundColor Cyan
        Write-Host ""
        
        $owner = Read-Host "Enter your GitHub username/organization"
        $repo = Read-Host "Enter repository name"
        
        Write-Host ""
        Write-Host "You'll need a GitHub Personal Access Token with 'repo' permissions" -ForegroundColor Yellow
        Write-Host "Create one at: https://github.com/settings/tokens" -ForegroundColor Yellow
        Write-Host ""
        
        $token = Read-Host "Enter your GitHub Personal Access Token" -AsSecureString
        $tokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
        
        $env:GITHUB_TOKEN = $tokenPlain
        
        Write-Host ""
        Write-Host "Bootstrapping Flux CD..." -ForegroundColor Yellow
        
        flux bootstrap github `
            --owner=$owner `
            --repository=$repo `
            --branch=minikube `
            --path=clusters/minikube `
            --personal `
            --token-auth
    }
    
    "2" {
        Write-Host ""
        Write-Host "=== GitLab Bootstrap ===" -ForegroundColor Cyan
        Write-Host ""
        
        $owner = Read-Host "Enter your GitLab username/group"
        $repo = Read-Host "Enter repository name"
        
        Write-Host ""
        Write-Host "You'll need a GitLab Personal Access Token with 'api' and 'write_repository' permissions" -ForegroundColor Yellow
        Write-Host "Create one at: https://gitlab.com/-/profile/personal_access_tokens" -ForegroundColor Yellow
        Write-Host ""
        
        $token = Read-Host "Enter your GitLab Personal Access Token" -AsSecureString
        $tokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
        
        $env:GITLAB_TOKEN = $tokenPlain
        
        Write-Host ""
        Write-Host "Bootstrapping Flux CD..." -ForegroundColor Yellow
        
        flux bootstrap gitlab `
            --owner=$owner `
            --repository=$repo `
            --branch=minikube `
            --path=clusters/minikube `
            --token-auth
    }
    
    "3" {
        Write-Host ""
        Write-Host "=== Generic Git Bootstrap ===" -ForegroundColor Cyan
        Write-Host ""
        
        $gitUrl = Read-Host "Enter your Git repository URL (e.g., https://git.example.com/user/repo.git)"
        $username = Read-Host "Enter Git username"
        $password = Read-Host "Enter Git password/token" -AsSecureString
        $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        
        Write-Host ""
        Write-Host "Bootstrapping Flux CD..." -ForegroundColor Yellow
        
        flux bootstrap git `
            --url=$gitUrl `
            --branch=minikube `
            --path=clusters/minikube `
            --username=$username `
            --password=$passwordPlain
    }
    
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Bootstrap Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait for Flux to reconcile: flux get kustomizations --watch"
Write-Host "2. Check Helm releases: flux get helmreleases -A"
Write-Host "3. Verify pods are running:"
Write-Host "   kubectl get pods -n istio-system"
Write-Host "   kubectl get pods -n ingress-nginx"
Write-Host "   kubectl get pods -n kong"
Write-Host "   kubectl get pods -n demo"
Write-Host ""
Write-Host "For testing instructions, see: docs/test-commands.md" -ForegroundColor Cyan
