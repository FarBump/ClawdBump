# ClawdBump Bot - Railway Deployment Dockerfile
FROM node:20-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm
RUN npm install -g pnpm@10.23.0

# Copy package files
COPY package.json ./
COPY pnpm-workspace.yaml ./
COPY pnpm-lock.yaml ./

# Copy patches directory
COPY patches ./patches/

# Install dependencies (use --no-frozen-lockfile for Railway)
RUN pnpm install --no-frozen-lockfile

# Copy all source code
COPY . .

# Build TypeScript to JavaScript
RUN pnpm build

# Create clawdbot directories
RUN mkdir -p /root/.clawdbot/workspace

# Expose default port
EXPOSE 18789

# Start gateway with Railway PORT (use shell form for env var expansion)
CMD node dist/entry.js gateway run --port ${PORT:-18789} --bind 0.0.0.0
