# Deno Devcontainer Project

This project provides a consistent development environment for a Deno application using DevPod and Podman (or Docker) based on the Dev Containers specification.

## Features

### Development Environment

- **Base Image**: `debian:bookworm-slim` (Minimal Debian base)
- **Container Runtime Integration**: Configured for Podman using `--userns=keep-id` for seamless user mapping (also compatible with Docker).
- **Core Tools**:
  - Deno (latest version, installed via official script)
  - `curl`
  - `unzip`
- **Dev Container Features**:
  - Git (latest version via `ghcr.io/devcontainers/features/git:1`)
  - Neovim (latest version via `ghcr.io/sinhaaritro/devcontainer-feature/neovim`)
- **User**: Runs as non-root `dev` (UID/GID 1000:1000 by default, customizable via build arguments in `Containerfile`).
- **Workspace**: `/home/dev/workspace` (Mounts your project code)
- **Port Forwarding**: Port `8000` inside the container is mapped to `8000` on the host.
- **Deno Cache**: Uses `/deno-dir` inside the container for persistent caching between runs.
- **Configuration**: Managed via `.devcontainer/Containerfile` and `.devcontainer/devcontainer.json`.`

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

2. **Start Dev Environment with DevPod**:
    - Ensure Podman is running.
    - Run the following command in your project directory:

        ```sh
        # Use --provider podman (or docker if you prefer)
        # --ide none prevents DevPod from trying to launch a specific IDE connection
        devpod up . --provider podman --ide none
        ```

    - DevPod will use the `.devcontainer/devcontainer.json` and `.devcontainer/Containerfile` to build and start the container. The `--userns=keep-id` option in `devcontainer.json` helps map your host user permissions correctly when using Podman.

3. **Access the Container Shell**:
    - Find your workspace name: `devpod list`
    - Connect via SSH:

        ```sh
        devpod ssh <your-workspace-name>
        ```

    - You will be logged in as the `dev` user inside the container's `/home/dev/workspace` directory.

4. **Run the Application (Inside the Container)**:
    - Navigate to your project code if needed (usually already in `/home/dev/workspace`).
    - Start the Deno server (adjust flags as needed for your `main.ts`):

        ```sh
        deno run --allow-net --allow-env --allow-read --allow-write main.ts
        ```

5. **Test Endpoints (From your Host Machine)**:
    - Since port 8000 is forwarded, you can use `curl` on your host:

        ```sh
        # Example tests (adjust to your actual endpoints)
        curl http://localhost:8000/health
        curl http://localhost:8000/
        curl -X PUT -H "Content-Type: application/json" \
             -d '{"species":"Oak","age":10,"location":"Park"}' \
             http://localhost:8000/trees/1
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
