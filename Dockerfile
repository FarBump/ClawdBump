# FarBump Bot - Railway Deployment Dockerfile
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml* ./
COPY patches ./patches/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build TypeScript
RUN pnpm build

# Create clawdbot config directory
RUN mkdir -p /root/.clawdbot/workspace/skills

# Copy FarBump skill
COPY skills/farbump /root/.clawdbot/workspace/skills/farbump/

# Copy production config template
COPY railway-config.json /root/.clawdbot/clawdbot.json

# Expose gateway port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:18789/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); })"

# Start gateway
CMD ["node", "dist/entry.js", "gateway", "run", "--port", "18789", "--bind", "0.0.0.0"]
