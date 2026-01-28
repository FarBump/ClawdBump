# ClawdBump Bot - Railway Deployment
FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install clawdbot globally from npm (stable release)
RUN npm install -g clawdbot@latest

# Create clawdbot directories
RUN mkdir -p /data/.clawdbot /data/workspace

# Set environment variables for persistent storage
ENV CLAWDBOT_STATE_DIR=/data/.clawdbot
ENV CLAWDBOT_WORKSPACE_DIR=/data/workspace

# Expose port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s \
  CMD curl -f http://localhost:${PORT:-18789}/health || exit 1

# Start gateway
CMD clawdbot gateway run --port ${PORT:-18789} --bind 0.0.0.0
