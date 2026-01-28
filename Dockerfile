# ClawdBump Bot - Railway Deployment
FROM node:20-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Enable corepack for pnpm
RUN corepack enable

# Copy package files
COPY package.json pnpm-workspace.yaml ./
COPY patches ./patches/

# Install ALL dependencies (no lockfile since it's gitignored)
RUN pnpm install

# Copy source code
COPY tsconfig.json ./
COPY src ./src/
COPY scripts ./scripts/

# Build TypeScript (just core, skip UI)
RUN pnpm exec tsc -p tsconfig.json

# Production stage
FROM node:20-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable corepack
RUN corepack enable

# Copy package files for production install
COPY package.json pnpm-workspace.yaml ./
COPY patches ./patches/

# Install production dependencies only
RUN pnpm install --prod

# Copy built files from builder
COPY --from=builder /app/dist ./dist/

# Create data directories
RUN mkdir -p /data/.clawdbot /data/workspace

# Environment variables
ENV NODE_ENV=production
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV CLAWDBOT_WORKSPACE_DIR=/data/workspace

# Expose port
EXPOSE 18789

# Start gateway (use shell form for PORT env var)
CMD node dist/entry.js gateway run --port ${PORT:-18789} --bind 0.0.0.0
