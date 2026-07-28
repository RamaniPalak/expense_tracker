# Stage 1: Build TypeScript
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY tsconfig.json ./
COPY src/ ./src/

RUN npm run build

# Stage 2: Production image (minimal)
FROM node:22-alpine AS runner

WORKDIR /app

# Only copy production dependencies
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

# Copy compiled JS from builder
COPY --from=builder /app/dist ./dist

# Non-root user for security
RUN addgroup -S genkit && adduser -S genkit -G genkit
USER genkit

ENV PORT=3001
ENV NODE_ENV=production

EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3001/health || exit 1

CMD ["node", "dist/index.js"]
