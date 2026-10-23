# How to access EKS

Run these after `terraform apply` has finished. Examples use dev – swap `dev` for `qa` or `prod`.

1. **Go to the project folder**
   ```bash
   cd ~/"niyaazs_scripts/Terraform Training/Terraform-Project-Cap"
   ```

2. **Connect kubectl to the cluster**
   ```bash
   aws eks update-kubeconfig --region af-south-1 --name adonis-n-eks-dev
   ```

3. **Check the node is ready**
   ```bash
   kubectl get nodes
   ```

4. **Deploy nginx**
   ```bash
   kubectl apply -f k8s/nginx.yaml
   ```

5. **Check the pod is running** – repeat until `my-pod` shows `Running`
   ```bash
   kubectl get pods
   ```

6. **Check the service** – `my-service` should show `80:30007`
   ```bash
   kubectl get svc
   ```

7. **Get the node's public IP** – copy the `EXTERNAL-IP` value
   ```bash
   kubectl get nodes -o wide
   ```

8. **Open in your browser** – you should see "Welcome to nginx!"
   ```
   http://<EXTERNAL-IP>:30007
   ```

9. **Clean up when done** (EKS costs money every hour)
   ```bash
   kubectl delete -f k8s/nginx.yaml
   terraform destroy -var-file=envs/dev/dev.tfvars
   ```

## Note

kubectl not installed? Install it once:
```bash
cd ~/.local/bin
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
```
