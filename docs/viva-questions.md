# Viva Questions & Answers — DeployShift

## Blue-Green Deployment

**Q1: What is blue-green deployment?**
Blue-green deployment is a release strategy where two identical production environments (Blue and Green) run simultaneously. At any time, only one serves live traffic. New releases are deployed to the idle environment, validated, and then traffic is switched over. If anything goes wrong, traffic is instantly switched back.

**Q2: Why is blue-green deployment useful?**
- Near-zero downtime during releases
- Instant rollback — just switch the traffic back
- The new version can be fully validated before users see it
- Reduces risk of failed deployments reaching production users

**Q3: What is the difference between blue-green and canary deployment?**
Blue-green switches 100% of traffic at once. Canary gradually routes a small percentage (e.g., 5%) of traffic to the new version and increases it over time. Canary is more granular but more complex to implement.

**Q4: What is the difference between rollback and rollout undo in blue-green?**
In blue-green, **rollback** means changing the Service selector back to the old version — the old pods are already running, so it's instant. **Rollout undo** (`kubectl rollout undo`) reverts a Deployment's pod template to a previous revision, which requires creating new pods. In blue-green, we never modify the Deployments — only the Service selector changes.

## Kubernetes

**Q5: How does a Kubernetes Service route traffic?**
A Service uses **label selectors** to find matching pods. It maintains an Endpoints object listing the IP addresses of all ready pods that match the selector. When traffic arrives, kube-proxy distributes it across those endpoints. In our project, changing the `version` label in the selector switches traffic between Blue and Green pods.

**Q6: What is the difference between liveness and readiness probes?**
- **Liveness probe**: Checks if the container is alive. If it fails, Kubernetes restarts the container.
- **Readiness probe**: Checks if the container is ready to receive traffic. If it fails, the pod is removed from Service endpoints but NOT restarted.

**Q7: What is a Kubernetes Namespace and why use one?**
A Namespace is a logical partition within a cluster. We use the `blue-green` namespace to isolate our project's resources from other workloads and system components.

**Q8: What does `imagePullPolicy: Never` mean?**
It tells Kubernetes to never pull the image from a registry — it uses only the local image cache. This is necessary for Docker Desktop Kubernetes because images built locally are already available in the same Docker daemon.

**Q9: What are resource requests and limits?**
- **Requests**: The minimum resources guaranteed to a container. The scheduler uses these to decide pod placement.
- **Limits**: The maximum resources a container can use. If it exceeds memory limits, it's killed (OOMKilled). If it exceeds CPU limits, it's throttled.

## Docker

**Q10: Why use a multi-stage Docker build?**
Multi-stage builds separate the build environment from the runtime environment. We install all dependencies in the builder stage but copy only production dependencies to the final image. This results in a smaller, more secure image.

**Q11: Why run containers as a non-root user?**
If a container is compromised, a non-root user limits what an attacker can do. It follows the principle of least privilege — the app doesn't need root access, so it shouldn't have it.

**Q12: Why does the application listen on 0.0.0.0?**
Inside a container, `localhost` or `127.0.0.1` only accepts connections from within the container itself. `0.0.0.0` means "all network interfaces," which allows Kubernetes and Docker to route external traffic into the container.

## CI/CD

**Q13: What does `npm ci` do differently from `npm install`?**
`npm ci` installs dependencies exactly as specified in `package-lock.json`, deletes `node_modules` first, and fails if the lock file is out of sync with `package.json`. It's faster and more reproducible for CI environments.

**Q14: Why can't GitHub Actions deploy to a local Kubernetes cluster?**
GitHub-hosted runners are cloud VMs that cannot directly reach a developer's local machine. Deploying to Docker Desktop Kubernetes would require exposing the cluster publicly (a security risk) or using a tunnel.

**Q15: How would you securely store Kubernetes credentials for CI/CD?**
Use GitHub Secrets (Settings → Secrets → Actions). Store the base64-encoded kubeconfig as a secret. The CI workflow reads it with `${{ secrets.KUBE_CONFIG }}`. Never commit credentials to the repository.

## Application

**Q16: Why use an in-memory data store?**
For simplicity. It avoids database setup complexity and lets us focus on the deployment strategy. The trade-off is that data is lost when pods restart. A production system would use a persistent database.

**Q17: How do the two versions differ?**
v2.0.0 (Green) adds:
- A `release` field in the root endpoint with codename and feature list
- A `/api/students/search` endpoint (not available in v1)
- Deployment metadata in `/api/version`
- An additional `search` capability

These are genuine code-level differences, not just an environment variable change.

**Q18: What is graceful shutdown and why is it important?**
When Kubernetes sends SIGTERM to stop a pod, graceful shutdown lets the application finish processing in-flight requests before exiting. Without it, requests could be dropped mid-response, causing errors for users.

## General DevOps

**Q19: What is zero-downtime deployment?**
A deployment strategy where users experience no interruption. Blue-green achieves near-zero downtime because the old version keeps running until the new version is validated and traffic is switched. However, in-flight requests at the exact moment of switching may still be affected.

**Q20: What database considerations exist for blue-green deployment?**
Both versions must be compatible with the same database schema. Schema migrations must be backward-compatible: add new columns (nullable or with defaults), don't rename or remove columns that the old version uses. This is called "expand and contract" migration.
