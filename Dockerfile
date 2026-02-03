# Build stage
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY apps/ga_personal/mix.exs apps/ga_personal/
COPY apps/ga_personal_web/mix.exs apps/ga_personal_web/
RUN mix do deps.get --only prod, deps.compile

# Copy application code
COPY apps ./apps
COPY config ./config

# Compile and build release
RUN mix do compile, phx.digest, release

# Runtime stage
FROM alpine:3.18 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++ \
    libgcc

# Create app user
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

# Set working directory
WORKDIR /app

# Copy release from builder
COPY --from=builder --chown=app:app /app/_build/prod/rel/ga_personal ./

# Switch to app user
USER app

# Expose port
EXPOSE 4000

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/app/bin/ga_personal", "rpc", "1 + 1"]

# Start application
CMD ["/app/bin/ga_personal", "start"]
