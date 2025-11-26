FROM elixir:latest

# Install build tools
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

# Copy mix.exs and mix.lock if exists
COPY mix.exs ./
COPY mix.lock* ./

# Install dependencies (will update mix.lock if needed)
RUN mix deps.get

# Copy source
COPY . .

# Compile
RUN mix compile

EXPOSE 4000

CMD ["./entrypoint.sh"]
