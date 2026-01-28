# ClawdBump Bot - Railway Deployment
# Based on successful clawdbot-railway-template
FROM node:20-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    make \
    g++ \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install pnpm globally
RUN npm install -g pnpm@10.23.0

# Copy ALL files (simpler, like successful template)
COPY . .

# Skip postinstall script (not needed in Docker)
ENV CLAWDBOT_SKIP_POSTINSTALL=1

# Install all dependencies (including dev deps needed for build)
RUN pnpm install --ignore-scripts

# Build TypeScript to JavaScript
RUN pnpm build

# Create empty workspace.yaml to prevent "No projects matched" error
RUN echo "packages: []" > pnpm-workspace.yaml

# Remove dev dependencies after build
ENV CI=true
RUN pnpm prune --prod

# Clean up source files and lockfile (keep extensions/ structure for runtime discovery)
RUN rm -rf src/ test/ scripts/ apps/ ui/ docs/ .git/ \
    && find extensions/ -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) ! -path "*/node_modules/*" -delete \
    && rm -f pnpm-lock.yaml

# Remove pnpm (not needed at runtime, only node)
RUN npm uninstall -g pnpm

# Create data directories
RUN mkdir -p /data/.clawdbot /data/workspace

# Environment variables
ENV NODE_ENV=production
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV CLAWDBOT_WORKSPACE_DIR=/data/workspace

# Expose port
EXPOSE 18789

# Start gateway (shell form for PORT env var expansion)
CMD node dist/entry.js gateway run --bind 0.0.0.0 --port ${PORT:-18789}
