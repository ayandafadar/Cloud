# Test Cases — DeployShift Blue-Green Deployment

## Unit & Integration Tests (Jest + Supertest)

| # | Test Case | Endpoint | Method | Expected Status | Expected Behavior |
|---|-----------|----------|--------|-----------------|-------------------|
| 1 | Root endpoint returns app info | `/` | GET | 200 | Returns application name, version, environment, status |
| 2 | Health check returns healthy | `/health` | GET | 200 | Returns `status: "healthy"`, uptime, memory |
| 3 | Readiness check returns ready | `/ready` | GET | 200 | Returns `ready: true`, all checks pass |
| 4 | Version endpoint returns info | `/api/version` | GET | 200 | Returns version, environment, capabilities |
| 5 | List all students | `/api/students` | GET | 200 | Returns 5 seeded students |
| 6 | Get student by ID | `/api/students/1` | GET | 200 | Returns Alice Johnson |
| 7 | Get non-existent student | `/api/students/999` | GET | 404 | Returns Not Found error |
| 8 | Create student (valid) | `/api/students` | POST | 201 | Returns new student with generated ID |
| 9 | Create student (missing name) | `/api/students` | POST | 400 | Returns validation error for name |
| 10 | Create student (invalid email) | `/api/students` | POST | 400 | Returns validation error for email |
| 11 | Create student (invalid year) | `/api/students` | POST | 400 | Returns validation error for year |
| 12 | Create student (empty body) | `/api/students` | POST | 400 | Returns validation errors |
| 13 | Update student (valid) | `/api/students/1` | PUT | 200 | Returns updated student |
| 14 | Update non-existent student | `/api/students/999` | PUT | 404 | Returns Not Found error |
| 15 | Update with invalid data | `/api/students/1` | PUT | 400 | Returns validation error |
| 16 | Delete student | `/api/students/1` | DELETE | 200 | Returns deleted student, count decreases |
| 17 | Delete non-existent student | `/api/students/999` | DELETE | 404 | Returns Not Found error |
| 18 | Unknown route | `/api/nonexistent` | GET | 404 | Returns Not Found with route info |

## Deployment Verification Scenarios

| # | Scenario | Verification Steps | Expected Result |
|---|----------|-------------------|-----------------|
| S1 | Blue is active, serves v1.0.0 | Deploy Blue → port-forward → `GET /api/version` | `version: "1.0.0"`, `environment: "blue"` |
| S2 | Green deployed alongside Blue | Deploy Green → verify pods → Blue still serves production | Green pods ready, production returns v1.0.0 |
| S3 | Switch traffic to Green | Patch service selector → `GET /api/version` | `version: "2.0.0"`, `environment: "green"` |
| S4 | Green validation fails | Green not ready → attempt switch | Switch rejected, production stays on Blue |
| S5 | Rollback from Green to Blue | Patch service selector back → verify | `version: "1.0.0"`, Blue pods healthy |
| S6 | Pod failure with readiness | Delete a pod → K8s recreates → service routes to ready pods only | No 503 errors during pod replacement |

## v2 Feature Differentiation

| Feature | v1.0.0 (Blue) | v2.0.0 (Green) |
|---------|---------------|----------------|
| Root endpoint `release` field | Not present | Contains release name, codename, features |
| `/api/students/search` | Not available (404) | Available — search by name |
| `/api/version` capabilities | `['crud', 'health-checks', 'structured-logging']` | `['crud', 'search', 'health-checks', 'structured-logging']` |
| Deployment metadata | Not present | Contains strategy, activeSlot, previousSlot |
