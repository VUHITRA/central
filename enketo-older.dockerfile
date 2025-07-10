# ODK Central Enketo - Older Version for Testing
# This dockerfile creates an older version of the Enketo service
# to help reproduce and test historical issues

FROM node:18.20.4-alpine as intermediate

# Install system dependencies
RUN apk add --no-cache git python3 make g++

# Set working directory
WORKDIR /usr/odk

# Clone Enketo Express at a specific older version
# You can modify this to use different versions for testing
RUN git clone https://github.com/enketo/enketo-express.git . && \
    git checkout v2.8.0

# Install dependencies
RUN npm ci --omit=dev --no-audit --fund=false

# Production stage
FROM node:18.20.4-alpine

# Install required packages
RUN apk add --no-cache \
    curl \
    netcat-openbsd

# Create enketo user and group
RUN addgroup -g 1000 enketo && adduser -D -u 1000 -G enketo enketo

# Set working directory
WORKDIR /usr/odk

# Copy from intermediate stage
COPY --from=intermediate --chown=enketo:enketo /usr/odk /usr/odk

# Copy configuration files
COPY files/enketo/config.json.template ./config/config.json.template
COPY files/enketo/start-enketo.sh ./start-enketo.sh
RUN chmod +x ./start-enketo.sh

# Copy secrets generation script
COPY files/enketo/generate-secrets.sh ./generate-secrets.sh
RUN chmod +x ./generate-secrets.sh

# Switch to enketo user
USER enketo

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8005/health || exit 1

# Expose port
EXPOSE 8005

# Default command
CMD ["./start-enketo.sh"]
