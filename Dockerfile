# ClawdBump Bot - Railway Deployment
FROM node:20-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable corepack for pnpm
RUN corepack enable

# Copy package files
COPY package.json pnpm-workspace.yaml ./
COPY patches ./patches/

# Install ALL dependencies (includes dev deps for build)
RUN pnpm install

# Copy source code
COPY tsconfig.json ./
COPY src ./src/
COPY scripts ./scripts/

# Build TypeScript
RUN pnpm exec tsc -p tsconfig.json

# Prune dev dependencies (keep only production)
RUN pnpm prune --prod

# Production stage
FROM node:20-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package.json pnpm-workspace.yaml ./

# Copy node_modules from builder (already has production deps only)
COPY --from=builder /app/node_modules ./node_modules

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
