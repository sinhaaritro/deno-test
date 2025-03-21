# Deno Test Project

This project is a Deno-based application with separate development and production environments. It uses Docker and DevPod for development and Docker Compose for production deployment.

## Features

### Development Environment

- **Base Image**: Debian Bookworm Slim
- **Tools**:
  - Deno (latest version)
  - Neovim (latest version)
  - Node.js, npm, luarocks (for Neovim plugins/LSP)
  - curl, jq, unzip (utility tools)
- **User**: Runs as `dev` (UID/GID 1000:1000, customizable)
- **Workspace**: `/home/dev/workspace`
- **Port**: 8000 (mapped to host)
- **Setup**: Managed via `.devcontainer/Containerfile` and `.devcontainer/devcontainer.json`

### Production Environment

- **Base Image**: Debian Bookworm Slim (multi-stage build)
- **Tools**: Deno (latest version), minimal runtime dependencies (curl)
- **User**: Runs as `app` (UID/GID 1001:1001)
- **Workspace**: `/app`
- **Port**: 8000 (mapped to host)
- **Healthcheck**: `/health` endpoint
- **Setup**: Managed via `Containerfile` and `compose.yaml`
- **Persistence**: Deno cache stored in a volume (`deno-data`)

### Application

- **Framework**: Hono (v4.7.4)
- **Endpoints**:
  - `GET /health`: Returns `{ "status": "healthy" }`
  - `GET /`: Returns `{ "message": "Hi this is working" }`
  - `PUT /trees/:id`: Updates a tree in Deno KV
- **KV Store**: Uses Deno KV for data persistence

## Prerequisites

- **Docker**: For building and running containers
- **DevPod**: For development environment (optional)
- **Deno**: For local testing (optional)
- **curl**: For testing endpoints

## Development Setup

1. **Clone the Repository**:

   ```sh
   git clone <repository-url>
   cd deno-test
   ```

2. **tart Dev Environment with DevPod**:

   ```sh
   devpod up . --provider docker --ide none
   ```

3. **Access the Container**:

   ```sh
   devpod ssh deno-test
   ```

4. **Run the Application**:

   ```sh
   deno run --allow-net --allow-env --allow-read --allow-write main.ts
   ```

5. **Test Endpoints**:

   ```sh
   curl http://localhost:8000/health
   curl http://localhost:8000/
   curl -X PUT -H "Content-Type: application/json" -d '{"species":"Oak","age":10,"location":"Park"}' http://localhost:8000/trees/1
   ```

## Production Setup

1. **Build the Production Image**:

   ```sh
   docker build -f Containerfile -t deno-app:production .
   ```

2. **Run with Docker Compose**:

   ```sh
   docker compose -f compose.yaml up -d
   ```

   - Starts the app in detached mode with health monitoring.

3. **Test Endpoints**:

   ```sh
   curl http://localhost:8000/health
   curl http://localhost:8000/
   curl -X PUT -H "Content-Type: application/json" -d '{"species":"Oak","age":10,"location":"Park"}' http://localhost:8000/trees/1
   ```

4. **Check Health Status**:

   ```sh
   docker compose ps
   ```

   - Look for "healthy" in the STATE column.

5. **Stop the Application**:

   ```sh
   docker compose -f compose.yaml down
   ```

## File Structure

```text
/home/aritro/Projects/deno-test/
├── .devcontainer/
│   ├── Containerfile       # Development container setup
│   └── devcontainer.json   # DevContainer configuration
├── .git/                   # Git repository data
├── Containerfile           # Production container setup
├── compose.yaml            # Production Docker Compose config
├── deno.json               # Deno configuration
├── deno.lock               # Deno dependency lockfile
├── main.ts                 # Application entrypoint
├── main_test.ts            # Unit tests
└── README.md               # This file
```

## Notes

- **Development**: Use DevPod for a full dev environment with Neovim and tools.
- **Production**: Multi-stage build ensures a minimal image; Deno KV is in-memory unless a volume is added for persistence.
- **Customization**: Adjust `USER_UID`/`USER_GID` in Containerfiles if
