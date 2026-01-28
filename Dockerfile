# ClawdBump Bot - Railway Deployment Dockerfile
FROM node:20-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN npm install -g pnpm@10.23.0

# Copy package files first (for better caching)
COPY package.json pnpm-workspace.yaml ./
COPY pnpm-lock.yaml* ./

# Copy patches if they exist
COPY patches ./patches/ 2>/dev/null || true

# Install dependencies (no frozen lockfile for Railway compatibility)
RUN pnpm install --no-frozen-lockfile || pnpm install

# Copy source code
COPY . .

# Build TypeScript
RUN pnpm build

# Create clawdbot directories
RUN mkdir -p /root/.clawdbot/workspace

# Expose port (Railway will inject PORT env var)
EXPOSE ${PORT:-18789}

# Start gateway (use PORT from Railway environment)
CMD node dist/entry.js gateway run --port ${PORT:-18789} --bind 0.0.0.0
