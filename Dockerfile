# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Install dependencies first for layer caching
COPY package.json package-lock.json ./
RUN npm ci --only=production

# ---- Production stage ----
FROM node:20-alpine

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src/app

# Copy only production node_modules from builder
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy application code
COPY app/ ./app/
COPY package.json ./

# Set ownership
RUN chown -R appuser:appgroup /usr/src/app

USER appuser

# Configure environment defaults
ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

# Health check built into the image
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "app/server.js"]
