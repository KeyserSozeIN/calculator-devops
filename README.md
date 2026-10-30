# Calculator REST API: End-to-End CI/CD

A small Spring Boot calculator API wrapped in a fully automated pipeline:
**GitHub → Jenkins → Maven → Docker → Docker Hub → Docker Compose (app + Nginx)**.

Push a commit and Jenkins builds, tests, containerizes, pushes and redeploys it automatically.

## Tech stack
Java 17 · Spring Boot 3 (Web + Actuator) · Maven · JUnit 5 / MockMvc · Docker (multi-stage) · Docker Compose · Nginx · Jenkins

## API

| Operation | Endpoint |
|-----------|----------|
| Add       | `GET /api/v1/add?a=2&b=3` |
| Subtract  | `GET /api/v1/subtract?a=5&b=2` |
| Multiply  | `GET /api/v1/multiply?a=4&b=3` |
| Divide    | `GET /api/v1/divide?a=8&b=2` (`b=0` → HTTP 400) |
| Health    | `GET /actuator/health` |

Success response:

```json
{ "operation": "add", "a": 2, "b": 3, "result": 5 }
```

Error response (HTTP 400: division by zero, missing or non-numeric parameter):

```json
{ "status": 400, "error": "Bad Request", "message": "Division by zero is not allowed", "timestamp": "..." }
```

## Build and test

```bash
mvn clean package        # builds target/calculator.jar
mvn test                 # unit + MockMvc tests, XML reports in target/surefire-reports/
```

## Run

```bash
# 1) Plain JAR
java -jar target/calculator.jar
curl "http://localhost:8080/api/v1/add?a=2&b=3"

# 2) Single Docker container
docker build -t calculator:local .
docker run -p 8080:8080 calculator:local

# 3) Full stack (app + Nginx reverse proxy) with Docker Compose
#    The compose file pulls the image from Docker Hub (set your username in docker-compose.yml)
docker compose up -d
curl "http://localhost:8081/api/v1/multiply?a=6&b=7"
curl  http://localhost:8081/actuator/health
```

The Nginx proxy listens on **8081** and forwards to the calculator container on the private `calc-net` network.

## CI/CD pipeline (Jenkinsfile)

| Stage | What it does |
|-------|--------------|
| Checkout | Pulls the latest code from GitHub (webhook or SCM polling trigger) |
| Build | `mvn clean package -DskipTests` |
| Test | `mvn test`, publishes JUnit XML, fails the build on any test failure |
| Docker Build | Builds the image tagged with the build number (and `latest`) |
| Push | Pushes to Docker Hub using the Jenkins credential `dockerhub-creds` |
| Deploy | `docker compose up -d`, then waits for `/actuator/health` to report UP |

An email is sent on success or failure. Re-running is safe: Compose uses a fixed project name, so a re-run just updates the running stack.

## Repository layout

```
├── src/main/java/...     Spring Boot app (controller, service, error handler)
├── src/test/java/...     JUnit 5 + MockMvc tests
├── pom.xml
├── Dockerfile            multi-stage, non-root, slim JRE
├── .dockerignore
├── docker-compose.yml    calculator + nginx, healthcheck, restart policy, network
├── nginx/nginx.conf
├── Jenkinsfile
└── .gitignore
```
