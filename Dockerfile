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

# Install dependencies and build
RUN pnpm install --prod --ignore-scripts && \
    pnpm build || (pnpm install --ignore-scripts && pnpm build)

# Clean up to reduce image size
RUN rm -rf src/ test/ scripts/ apps/ ui/ docs/ .git/

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
