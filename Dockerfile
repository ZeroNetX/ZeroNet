FROM python:3.13-alpine AS builder

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install build dependencies
RUN apk --no-cache add \
    build-base \
    git \
    autoconf automake libtool \
    libffi-dev openssl-dev \
    musl-dev

# Install Python deps
RUN python -m venv /app/venv && \
    . /app/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt

# -----------------------------
# Runtime image
FROM python:3.13-alpine

# Create app directory
WORKDIR /app

# Add non-root user
RUN addgroup -S zeronet && adduser -S -G zeronet zeronet

# Install runtime dependencies
RUN apk --no-cache add \
    tor tini openssl wget

# Configure tor
RUN echo "ControlPort 9051" >> /etc/tor/torrc && \
    echo "CookieAuthentication 1" >> /etc/tor/torrc

# Copy from builder
COPY --from=builder /app/venv /app/venv

# Copy application code
COPY --chown=zeronet:zeronet . /app

# Prepare directories
RUN mkdir -p /app/data /app/log && \
    chown -R zeronet:zeronet /app/data /app/log && \
    chmod 750 /app/data /app/log

# Set environment
ENV PATH="/app/venv/bin:$PATH" \
    VIRTUAL_ENV="/app/venv" \
    ENABLE_TOR=true \
    UI_IP=0.0.0.0 \
    UI_PORT=43110 \
    FILESERVER_PORT=26117 \
    ADDITIONAL_ARGS=""

# Switch to non-root user
USER zeronet

# Use Tini as init to handle signals gracefully
ENTRYPOINT ["/sbin/tini", "--"]

# The command the container runs with
CMD ["sh", "-c", "(! ${ENABLE_TOR} || tor&) && python zeronet.py --ui_ip ${UI_IP} --ui_port ${UI_PORT} --fileserver_port ${FILESERVER_PORT} ${ADDITIONAL_ARGS}"]

# Expose ports - using the environment variables
EXPOSE ${UI_PORT} ${FILESERVER_PORT}
