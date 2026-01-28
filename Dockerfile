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

# Remove pnpm IMMEDIATELY after build (before any prune/cleanup)
# This prevents "No projects matched" errors at container start
RUN npm uninstall -g pnpm

# Clean up source files (keep node_modules - don't prune to avoid pnpm errors)
RUN rm -rf src/ test/ scripts/ apps/ ui/ docs/ .git/ \
    && find extensions/ -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) ! -path "*/node_modules/*" -delete \
    && rm -f pnpm-lock.yaml pnpm-workspace.yaml

# Create data directories
RUN mkdir -p /data/.clawdbot /data/workspace

# Environment variables
ENV NODE_ENV=production
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV CLAWDBOT_WORKSPACE_DIR=/data/workspace

# Expose port
EXPOSE 18789

# Verify entry point exists and is executable
RUN test -f dist/entry.js || (echo "ERROR: dist/entry.js not found!" && ls -la dist/ && exit 1)
RUN chmod +x dist/entry.js || true

# Copy debug script
COPY debug-start.sh /app/debug-start.sh
RUN chmod +x /app/debug-start.sh

# Start gateway with debug script (shows more info)
CMD ["/app/debug-start.sh"]
