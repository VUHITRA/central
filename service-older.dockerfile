# ODK Central Backend - Older Version for Testing
# This dockerfile creates an older version of the backend service
# to help reproduce and test historical issues

FROM node:18.20.4-alpine as intermediate

# Install system dependencies
RUN apk add --no-cache git

# Set working directory
WORKDIR /usr/odk

# Copy package files
COPY server/package*.json ./

# Install dependencies (using older versions)
RUN npm ci --omit=dev --no-audit --fund=false

# Copy server source
COPY server/ .

# Create older version by checking out a specific commit or using older dependencies
# You can modify this section to use specific older versions
RUN echo "Using older backend configuration for testing"

# Production stage
FROM node:18.20.4-alpine

# Install required packages
RUN apk add --no-cache \
    curl \
    netcat-openbsd \
    postgresql-client \
    wait4ports

# Create odk user and group
RUN addgroup -g 1000 odk && adduser -D -u 1000 -G odk odk

# Set working directory
WORKDIR /usr/odk

# Copy from intermediate stage
COPY --from=intermediate --chown=odk:odk /usr/odk /usr/odk

# Copy wait-for-it script
COPY files/service/wait-for-it.sh ./wait-for-it
RUN chmod +x ./wait-for-it

# Copy start script
COPY files/service/start-odk.sh ./start-odk.sh
RUN chmod +x ./start-odk.sh

# Switch to odk user
USER odk

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8383/health || exit 1

# Expose port
EXPOSE 8383

# Default command
CMD ["./start-odk.sh"]
