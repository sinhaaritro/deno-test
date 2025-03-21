# Build Stage: Install Deno and cache dependencies
# - First stage builds and caches app dependencies
FROM debian:bookworm-slim AS builder

# - Avoids interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Install curl to fetch Deno
RUN apt-get update \
    # - curl is needed to download Deno installer
    && apt-get install -y curl \
    # - Cleans up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/* 

# Install Deno (latest version)
RUN \
    # - Fetches and installs the latest Deno version
    curl -fsSL https://deno.land/install.sh | sh \
    # - Makes Deno available globally
    && mv /root/.deno/bin/deno /usr/local/bin/deno 

# Set working directory
# - Directory for app code in the builder stage
WORKDIR /app

# Copy application code
# - Copies all project files (main.ts, deno.json, etc.)
COPY . .

# Cache Deno dependencies
# - Pre-caches dependencies for faster startup in runtime stage 
RUN deno cache main.ts 

# Runtime Stage: Minimal image with just Deno and app
# - Second stage creates a lean production image
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Define runtime user
# - Configures a non-root user for security
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
# - Brings Deno into the runtime image
COPY --from=builder /usr/local/bin/deno /usr/local/bin/deno

# Copy cached dependencies and app code from builder stage
# - Copies the app and cached deps
COPY --from=builder /app /app

# Switch to non-root user
# - Runs container as 'app' user for security
USER $USERNAME

# Set working directory
# - Sets the app directory as the working dir
WORKDIR /app

# Set Deno environment variable
# - Points Deno to the cache directory
ENV DENO_DIR=/deno-dir/

# Expose port 8000
# - Declares the port the app will listen on
EXPOSE 8000

# Run the application (adjust if your entrypoint differs)
# - Starts the Deno app with necessary permissions
# - --allow-net: For HTTP server
# - --allow-env: For environment variables
# - --allow-read/--allow-write: For Deno KV
CMD ["deno", "run", "--allow-net", "--allow-env", "--allow-read", "--allow-write", "main.ts"]
