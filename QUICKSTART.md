# Quick Start Guide

This guide will help you get the Flux CD demo up and running quickly.

## ⚡ Quick Start (5 minutes)

### Step 1: Ensure Minikube is Running

```powershell
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Verify it's running
minikube status
```

### Step 2: Bootstrap Flux CD

**Option A: Using the Bootstrap Script (Recommended)**

```powershell
# Run the interactive bootstrap script
.\bootstrap-flux.ps1
```

The script will guide you through:
- Checking prerequisites
- Choosing your Git provider (GitHub, GitLab, or Generic)
- Entering your credentials
- Bootstrapping Flux CD

**Option B: Manual Bootstrap (GitHub)**

```powershell
# Set your GitHub token
$env:GITHUB_TOKEN = "your-github-token"

# Bootstrap Flux
flux bootstrap github `
  --owner=your-username `
  --repository=flux-cd-ngnix-istio-kong-demo `
  --branch=minikube `
  --path=clusters/minikube `
  --personal
```

### Step 3: Watch the Deployment

```powershell
# Watch Flux reconciliation
flux get kustomizations --watch

# In another terminal, watch Helm releases
flux get helmreleases -A --watch
```

Wait for all Kustomizations to show "Ready" status (this may take 5-10 minutes).

### Step 4: Verify Deployments

```powershell
# Check infrastructure pods
kubectl get pods -n istio-system
kubectl get pods -n ingress-nginx
kubectl get pods -n kong

# Check application pods
kubectl get pods -n demo

# All pods should be in "Running" status
```

### Step 5: Test the Setup

```powershell
# Get Minikube IP
$MINIKUBE_IP = minikube ip

# Test Istio HTTP routing
curl -H "Host: httpbin.local" http://${MINIKUBE_IP}:30080/headers

# Test Istio TCP routing
echo "Hello Istio" | nc $MINIKUBE_IP 30900

# Test Nginx Ingress
curl -H "Host: nginx-demo.local" http://${MINIKUBE_IP}:30080

# Test Kong API Gateway
curl -H "Host: kong-demo.local" http://${MINIKUBE_IP}:32080
```

## 🎯 What Gets Deployed

### Infrastructure (Automatic via Flux CD)

1. **Istio Service Mesh** (`istio-system` namespace)
   - Istio Base
   - Istiod (Control Plane)
   - Istio Ingress Gateway (with TCP support)

2. **Nginx Ingress Controller** (`ingress-nginx` namespace)
   - Nginx Ingress Controller
   - Configured with NodePort

3. **Kong API Gateway** (`kong` namespace)
   - Kong Gateway (DB-less mode)
   - Kong Ingress Controller
   - Admin API enabled

### Applications (Automatic via Flux CD)

All applications are deployed in the `demo` namespace with Istio sidecar injection enabled:

1. **TCP Echo Server** - For testing Istio TCP routing
2. **HTTPBin** - For testing HTTP requests
3. **Nginx Demo** - Simple app with Nginx Ingress
4. **Kong Demo** - App with Kong plugins (rate-limiting, CORS)
5. **Podinfo** - Accessible via all three ingress methods

## 🔍 Verification Checklist

- [ ] Minikube is running
- [ ] Flux CD is bootstrapped
- [ ] All Kustomizations are "Ready"
- [ ] All HelmReleases are "Ready"
- [ ] All pods in `istio-system` are running
- [ ] All pods in `ingress-nginx` are running
- [ ] All pods in `kong` are running
- [ ] All pods in `demo` are running
- [ ] HTTP test through Istio works
- [ ] TCP test through Istio works
- [ ] HTTP test through Nginx works
- [ ] HTTP test through Kong works

## 📊 Service Endpoints

| Service | URL/Command | Port |
|---------|-------------|------|
| Istio HTTP | `curl -H "Host: httpbin.local" http://<minikube-ip>:30080` | 30080 |
| Istio TCP | `nc <minikube-ip> 30900` | 30900 |
| Nginx | `curl -H "Host: nginx-demo.local" http://<minikube-ip>:30080` | 30080 |
| Kong | `curl -H "Host: kong-demo.local" http://<minikube-ip>:32080` | 32080 |
| Kong Admin | `curl http://<minikube-ip>:32001/status` | 32001 |

## 🐛 Troubleshooting

### Flux Not Reconciling

```powershell
# Check Flux status
flux check

# Force reconciliation
flux reconcile kustomization infrastructure --with-source
flux reconcile kustomization apps --with-source

# Check for errors
flux logs --level=error
```

### Pods Not Starting

```powershell
# Check pod status
kubectl get pods -A | Select-String "0/"

# Describe problematic pod
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### Tests Failing

```powershell
# Verify Minikube IP
minikube ip

# Check if services are exposed
kubectl get svc -A | Select-String "NodePort"

# Test connectivity
Test-NetConnection -ComputerName $(minikube ip) -Port 30080
```

### Need to Start Over

```powershell
# Uninstall Flux
flux uninstall

# Or delete the entire cluster
minikube delete

# Then start fresh
minikube start --cpus=4 --memory=8192
.\bootstrap-flux.ps1
```

## 📚 Next Steps

1. **Explore the Applications**
   - See [test-commands.md](docs/test-commands.md) for detailed testing instructions
   - Try different endpoints and features

2. **Modify Configurations**
   - Edit files in the repository
   - Commit and push to the `minikube` branch
   - Watch Flux automatically apply changes

3. **Add Your Own Applications**
   - Create new manifests in `apps/base/`
   - Add them to `apps/base/kustomization.yaml`
   - Commit and push

4. **Learn More**
   - Read the [README.md](README.md) for architecture details
   - Explore Istio features (traffic management, security)
   - Try Kong plugins
   - Experiment with Nginx Ingress annotations

## 🎓 Learning Resources

- **Flux CD**: https://fluxcd.io/docs/
- **Istio**: https://istio.io/latest/docs/
- **Nginx Ingress**: https://kubernetes.github.io/ingress-nginx/
- **Kong**: https://docs.konghq.com/
- **Minikube**: https://minikube.sigs.k8s.io/docs/

## 💡 Tips

- Use `flux get kustomizations` to see the reconciliation status
- Use `kubectl get pods -A` to see all pods across namespaces
- Use `minikube tunnel` if you want to access LoadBalancer services (not needed for this demo)
- Check logs with `kubectl logs -n <namespace> <pod-name>` for debugging
- Use `flux suspend kustomization <name>` to temporarily stop reconciliation
- Use `flux resume kustomization <name>` to resume reconciliation

## ⚠️ Important Notes

- This setup is for **development/learning purposes only**
- Minikube should have at least 4 CPUs and 8GB RAM
- The first deployment may take 5-10 minutes
- Some images may take time to download
- If you encounter issues, check the troubleshooting section
- All services use NodePort for easy access on Minikube

---

**Happy Learning! 🚀**

For detailed testing instructions, see [docs/test-commands.md](docs/test-commands.md)
