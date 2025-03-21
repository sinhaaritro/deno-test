# Build Stage: Install Deno and cache dependencies
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install curl to fetch Deno
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*

# Install Deno (latest version)
RUN curl -fsSL https://deno.land/install.sh | sh \
    && mv /root/.deno/bin/deno /usr/local/bin/deno 

# Set working directory
WORKDIR /app

# Copy application code (adjust if your entrypoint is different)
COPY . .

# Cache Deno dependencies (assuming a main.ts or similar entrypoint)
RUN deno cache main.ts 

# Runtime Stage: Minimal image with just Deno and app
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Define runtime user
ARG USERNAME=app
ARG USER_UID=1001
ARG USER_GID=1001

# Install only runtime dependencies (e.g., curl for Deno upgrades, if needed)
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME --shell /bin/bash \
    && mkdir -p /app /deno-dir \
    && chown -R $USER_UID:$USER_GID /app /deno-dir

# Copy Deno binary from builder stage
COPY --from=builder /usr/local/bin/deno /usr/local/bin/deno

# Copy cached dependencies and app code from builder stage
COPY --from=builder /app /app

# Switch to non-root user
USER $USERNAME

# Set working directory
WORKDIR /app

# Set Deno environment variable
ENV DENO_DIR=/deno-dir/

# Expose port 8000 (based on devcontainer.json)
EXPOSE 8000

# Run the application (adjust if your entrypoint differs)
CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "--allow-write", "main.ts"]
