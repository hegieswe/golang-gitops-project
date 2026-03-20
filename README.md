# Golang GitOps Project

A high-performance, lightweight HTTP server built with Go. This project is designed for a scalable GitOps-managed Kubernetes environment but is also fully functional as a standalone microservice.

## 🚀 Features

- **Lightweight**: Built with a multi-stage `Dockerfile` and based on Alpine Linux for a minimal footprint.
- **Microservices Oriented**: Designed with cloud-native principles, including health checks.
- **Container Ready**: Optimized for containerization and orchestrated environments.
- **API Endpoints**:
    - `/`: Main greeting message.
    - `/health`: Health status endpoint for monitoring and orchestration probes.

## 🛠 Prerequisites

Before you begin, ensure you have the following installed:
- [Go 1.21+](https://golang.org/dl/)
- [Docker](https://docs.docker.com/get-docker/)
- [git](https://git-scm.com/)

## 💻 Local Development

To run the application locally without Docker:

```bash
# Clone the repository
git clone <your-repo-url>
cd golang-gitops-project

# Run the server
go run main.go
```

The server will start at `http://localhost:8080`.

## 📦 Containerization

### Building the Image
You can build the Docker image using the standard Docker CLI:

```bash
docker build -t hegieswe/golang-gitops-project:latest .
```

### Running with Docker Compose
For quick local integration testing, a `docker-compose.yaml` file is provided:

```bash
docker-compose up -d
```

## 📂 Project Structure

- `main.go`: Application logic and HTTP handlers.
- `Dockerfile`: Multi-stage build configuration using Alpine.
- `docker-compose.yaml`: Local orchestration for testing.

---
Created and maintained by **hegieswe** for the DevOps GitOps project.
