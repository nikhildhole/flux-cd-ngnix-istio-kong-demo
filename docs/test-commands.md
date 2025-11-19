# Test Commands for Flux CD Demo

This document provides detailed test commands for verifying Istio, Nginx, and Kong deployments.

## Prerequisites

```powershell
# Get Minikube IP (save to variable)
$MINIKUBE_IP = minikube ip
Write-Host "Minikube IP: $MINIKUBE_IP"

# Verify all pods are running
kubectl get pods -n istio-system
kubectl get pods -n ingress-nginx
kubectl get pods -n kong
kubectl get pods -n demo
```

## 🔷 Istio Service Mesh Tests

### HTTP Traffic Tests

#### Test 1: HTTPBin Application

```powershell
# Basic request
curl -H "Host: httpbin.local" http://${MINIKUBE_IP}:30080/headers

# Get request with query parameters
curl -H "Host: httpbin.local" http://${MINIKUBE_IP}:30080/get?param1=value1

# POST request
curl -X POST -H "Host: httpbin.local" -H "Content-Type: application/json" `
  -d '{"test": "data"}' http://${MINIKUBE_IP}:30080/post

# Status code test
curl -H "Host: httpbin.local" http://${MINIKUBE_IP}:30080/status/200
curl -H "Host: httpbin.local" http://${MINIKUBE_IP}:30080/status/404
```

#### Test 2: Podinfo via Istio

```powershell
# Get podinfo home page
curl -H "Host: podinfo-istio.local" http://${MINIKUBE_IP}:30080/

# Get podinfo version
curl -H "Host: podinfo-istio.local" http://${MINIKUBE_IP}:30080/version

# Health check
curl -H "Host: podinfo-istio.local" http://${MINIKUBE_IP}:30080/healthz

# Get environment info
curl -H "Host: podinfo-istio.local" http://${MINIKUBE_IP}:30080/env
```

### TCP Traffic Tests

#### Test 3: TCP Echo Server

```powershell
# Simple TCP echo test
echo "Hello Istio TCP" | nc $MINIKUBE_IP 30900

# Expected output: hello-istio-tcp

# Multiple messages test
"Message 1", "Message 2", "Message 3" | ForEach-Object {
    echo $_ | nc $MINIKUBE_IP 30900
}

# Interactive TCP session (requires netcat)
nc $MINIKUBE_IP 30900
# Type messages and press Enter
# Press Ctrl+C to exit
```

#### Test 4: Verify TCP Connection

```powershell
# Test TCP connectivity
Test-NetConnection -ComputerName $MINIKUBE_IP -Port 30900

# Using telnet (if available)
telnet $MINIKUBE_IP 30900
```

### Istio Observability

```powershell
# Check Istio proxy status
kubectl exec -n istio-system deploy/istiod -- pilot-discovery request GET /debug/syncz | ConvertFrom-Json

# Get Istio configuration for demo namespace
istioctl proxy-config routes deploy/tcp-echo -n demo

# Analyze Istio configuration
istioctl analyze -n demo

# Check if sidecar is injected
kubectl get pods -n demo -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'
```

## 🟢 Nginx Ingress Controller Tests

### Test 5: Nginx Demo Application

```powershell
# Access Nginx demo page
curl -H "Host: nginx-demo.local" http://${MINIKUBE_IP}:30080

# With verbose output
curl -v -H "Host: nginx-demo.local" http://${MINIKUBE_IP}:30080

# Save response to file
curl -H "Host: nginx-demo.local" http://${MINIKUBE_IP}:30080 -o nginx-demo.html

# Open in browser (Windows)
Start-Process "http://${MINIKUBE_IP}:30080" -ArgumentList "-H 'Host: nginx-demo.local'"
```

### Test 6: Podinfo via Nginx

```powershell
# Access podinfo through Nginx
curl -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/

# Test different endpoints
curl -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/version
curl -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/healthz
curl -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/readyz

# Load test (requires Apache Bench)
ab -n 100 -c 10 -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/
```

### Nginx Metrics and Logs

```powershell
# Check Nginx ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50

# Follow logs in real-time
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Get Nginx configuration
kubectl exec -n ingress-nginx deploy/ingress-nginx-controller -- cat /etc/nginx/nginx.conf

# Check ingress resources
kubectl get ingress -n demo
kubectl describe ingress nginx-demo -n demo
```

## 🔶 Kong API Gateway Tests

### Test 7: Kong Demo Application

```powershell
# Basic request to Kong demo
curl -H "Host: kong-demo.local" http://${MINIKUBE_IP}:32080

# Test rate limiting (make multiple requests)
1..15 | ForEach-Object {
    Write-Host "Request $_"
    curl -H "Host: kong-demo.local" http://${MINIKUBE_IP}:32080
    Start-Sleep -Milliseconds 500
}
# After 10 requests per minute, you should see rate limit errors

# Test CORS headers
curl -H "Host: kong-demo.local" -H "Origin: http://example.com" `
  -H "Access-Control-Request-Method: GET" `
  -X OPTIONS http://${MINIKUBE_IP}:32080 -v
```

### Test 8: Podinfo via Kong

```powershell
# Access podinfo through Kong
curl -H "Host: podinfo-kong.local" http://${MINIKUBE_IP}:32080/

# Test with headers
curl -v -H "Host: podinfo-kong.local" http://${MINIKUBE_IP}:32080/headers

# POST request
curl -X POST -H "Host: podinfo-kong.local" -H "Content-Type: application/json" `
  -d '{"test": "kong"}' http://${MINIKUBE_IP}:32080/echo
```

### Test 9: Kong Admin API

```powershell
# List all services
curl http://${MINIKUBE_IP}:32001/services | ConvertFrom-Json | ConvertTo-Json -Depth 10

# List all routes
curl http://${MINIKUBE_IP}:32001/routes | ConvertFrom-Json | ConvertTo-Json -Depth 10

# List all plugins
curl http://${MINIKUBE_IP}:32001/plugins | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Get Kong status
curl http://${MINIKUBE_IP}:32001/status | ConvertFrom-Json

# Get Kong configuration
curl http://${MINIKUBE_IP}:32001/ | ConvertFrom-Json
```

### Kong Logs and Debugging

```powershell
# Check Kong logs
kubectl logs -n kong -l app.kubernetes.io/name=kong --tail=50

# Follow Kong logs
kubectl logs -n kong -l app.kubernetes.io/name=kong -f

# Check Kong Ingress Controller logs
kubectl logs -n kong -l app.kubernetes.io/component=ingress-controller --tail=50

# Describe Kong ingress
kubectl describe ingress kong-demo -n demo
```

## 🔄 Comparison Tests

### Test 10: Same Application via Different Ingresses

```powershell
# Podinfo via Nginx
$nginx_response = curl -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/ -s
Write-Host "Nginx Response:" $nginx_response

# Podinfo via Kong
$kong_response = curl -H "Host: podinfo-kong.local" http://${MINIKUBE_IP}:32080/ -s
Write-Host "Kong Response:" $kong_response

# Podinfo via Istio
$istio_response = curl -H "Host: podinfo-istio.local" http://${MINIKUBE_IP}:30080/ -s
Write-Host "Istio Response:" $istio_response
```

### Test 11: Performance Comparison

```powershell
# Requires Apache Bench (ab) or similar tool

# Test Nginx
ab -n 1000 -c 10 -H "Host: podinfo.local" http://${MINIKUBE_IP}:30080/

# Test Kong
ab -n 1000 -c 10 -H "Host: podinfo-kong.local" http://${MINIKUBE_IP}:32080/

# Test Istio
ab -n 1000 -c 10 -H "Host: podinfo-istio.local" http://${MINIKUBE_IP}:30080/
```

## 🔍 Verification Commands

### Check All Services

```powershell
# Get all services across namespaces
kubectl get svc -A | Select-String "istio|nginx|kong|demo"

# Get all ingress resources
kubectl get ingress -A

# Get all VirtualServices
kubectl get virtualservices -A

# Get all Gateways
kubectl get gateways -A
```

### Check Flux Reconciliation

```powershell
# Check all Kustomizations
flux get kustomizations

# Check all HelmReleases
flux get helmreleases -A

# Check sources
flux get sources all

# Force reconciliation
flux reconcile kustomization infrastructure --with-source
flux reconcile kustomization apps --with-source
```

### Network Debugging

```powershell
# Port forward to services for direct access
kubectl port-forward -n demo svc/httpbin 8080:8000
kubectl port-forward -n demo svc/podinfo 9898:9898
kubectl port-forward -n kong svc/kong-kong-admin 8001:8001

# Check DNS resolution inside cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup httpbin.demo.svc.cluster.local

# Check connectivity from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://httpbin.demo.svc.cluster.local:8000/get
```

## 📊 Expected Results Summary

| Test | Endpoint | Expected Result |
|------|----------|-----------------|
| HTTPBin via Istio | `httpbin.local:30080` | JSON response with headers |
| Podinfo via Istio | `podinfo-istio.local:30080` | Podinfo welcome page |
| TCP Echo | `nc <ip> 30900` | Returns "hello-istio-tcp" |
| Nginx Demo | `nginx-demo.local:30080` | HTML page with green header |
| Podinfo via Nginx | `podinfo.local:30080` | Podinfo welcome page |
| Kong Demo | `kong-demo.local:32080` | "Hello from Kong API Gateway!" |
| Podinfo via Kong | `podinfo-kong.local:32080` | Podinfo welcome page |
| Kong Admin API | `<ip>:32001/status` | Kong status JSON |

## 🐛 Troubleshooting Tests

```powershell
# If tests fail, run these diagnostic commands

# 1. Check if Minikube is running
minikube status

# 2. Check if all pods are ready
kubectl get pods -A | Select-String "0/"

# 3. Check events for errors
kubectl get events -n demo --sort-by='.lastTimestamp'
kubectl get events -n istio-system --sort-by='.lastTimestamp'

# 4. Check Flux for errors
flux logs --level=error --since=10m

# 5. Verify NodePort services
kubectl get svc -A -o wide | Select-String "NodePort"

# 6. Test basic connectivity
Test-NetConnection -ComputerName $MINIKUBE_IP -Port 30080
Test-NetConnection -ComputerName $MINIKUBE_IP -Port 32080
Test-NetConnection -ComputerName $MINIKUBE_IP -Port 30900
```

## 📝 Notes

- All HTTP tests use the `-H "Host: <hostname>"` header because we're using host-based routing
- TCP tests use `nc` (netcat) which should be available on most systems
- Replace `$MINIKUBE_IP` with your actual Minikube IP address
- Some tests require additional tools like `ab` (Apache Bench) or `hey` for load testing
- For Windows, you may need to install netcat separately or use WSL
