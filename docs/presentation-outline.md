# Demo Presentation Outline — DeployShift

## Slide 1: Title
- **DeployShift — Blue-Green Deployment of a RESTful Web Application Using Kubernetes and Automated CI/CD**
- Student Name, Course, Date

## Slide 2: Problem Statement
- Traditional deployments cause downtime during updates
- Rollbacks are slow and risky
- No way to validate new releases before exposing users to them
- Need: A deployment strategy that minimizes risk and allows instant rollback

## Slide 3: Objectives
- Demonstrate blue-green deployment with Kubernetes
- Build a complete REST API with health checks and version tracking
- Implement automated CI/CD with GitHub Actions
- Provide instant rollback capability
- Document the complete DevOps workflow

## Slide 4: Technology Stack
- Node.js + Express (REST API)
- Docker (Containerization)
- Kubernetes (Orchestration)
- GitHub Actions (CI/CD)
- Jest + Supertest (Testing)
- PowerShell (Automation Scripts)

## Slide 5: Architecture Overview
- Show the architecture diagram (see docs/architecture-diagrams.md)
- Explain: Two deployments, one service, selector-based routing

## Slide 6: Blue-Green Deployment Concept
- Blue = current production (v1.0.0)
- Green = new release (v2.0.0)
- Both run simultaneously
- Service selector determines which receives traffic
- Switch = change one label; Rollback = change it back

## Slide 7: Live Demo — Deploy Blue
- Show `scripts/deploy-blue.ps1` execution
- Port-forward and hit `/api/version` → v1.0.0
- Show `/api/students` CRUD operations

## Slide 8: Live Demo — Deploy Green
- Show `scripts/deploy-green.ps1` execution
- Both deployments visible in `kubectl get pods`
- Production still on Blue

## Slide 9: Live Demo — Switch Traffic
- Run `scripts/switch-to-green.ps1`
- `/api/version` now returns v2.0.0
- Show new Green features (search endpoint, release metadata)

## Slide 10: Live Demo — Rollback
- Run `scripts/rollback.ps1`
- `/api/version` returns v1.0.0 again
- Instant — no downtime, no pod restarts

## Slide 11: CI/CD Pipeline
- Show GitHub Actions workflow
- Automatic: lint, test, build Docker images
- Manual approval gate for production deployment
- Explain what would need credentials for full automation

## Slide 12: Key Kubernetes Concepts Used
- Deployments & ReplicaSets
- Services & Selectors
- Labels & Label Selectors
- Liveness & Readiness Probes
- Namespaces
- ConfigMaps
- Resource Limits

## Slide 13: Testing Results
- 18/18 automated tests passing
- Docker images build and run successfully
- All deployment scenarios verified

## Slide 14: Security Considerations
- Non-root containers
- No hardcoded secrets
- Input validation on all endpoints
- Resource limits prevent runaway containers
- Graceful shutdown on SIGTERM

## Slide 15: Limitations & Future Work
- In-memory data store (lost on restart)
- No TLS/HTTPS in local demo
- No canary deployment (partial traffic split)
- Future: Add database, Prometheus monitoring, Helm charts, canary releases

## Slide 16: Conclusion
- Blue-green deployment enables safe, instant rollbacks
- Kubernetes Services make traffic switching trivial
- CI/CD automates quality gates
- The pattern scales to production workloads

## Slide 17: Q&A
- Prepared answers in docs/viva-questions.md
