# ZipCast

ZipCast is a Ruby on Rails weather lookup app built for a take-home assessment.
It accepts a street address, resolves it through Google Geocoding, fetches the
forecast for the address ZIP code, caches forecast responses for 30 minutes, and
shows when a result came from cache.

## Requirements Covered

- Address input
- Weather lookup by ZIP code
- Current temperature
- High and low temperatures
- Extended forecast
- 30-minute cache by ZIP code
- Cache hit indicator

## Technical Choices

- Ruby on Rails 8
- PostgreSQL
- Turbo + Stimulus + ERB
- Google Geocoding API for address resolution
- Open-Meteo API for forecast data
- `Rails.cache` for ZIP-based caching

## Credentials

This project stores the Google Geocoding API key in Rails credentials.

For review purposes, place the provided `master.key` file at:

```text
config/master.key
```

If you need to edit credentials locally, run:

```bash
bin/rails credentials:edit
```

Store the Google Geocoding API key in this shape:

```yml
google:
  geocoding_api_key: your_google_geocoding_api_key
```

## Setup

After placing `config/master.key`, create a local `.env` file:

```bash
cat <<'EOF' > .env
# Optional: override the default Open-Meteo API base URL.
# OPEN_METEO_BASE_URL=https://api.open-meteo.com
EOF
```

Then run:

```bash
bin/setup
```

`bin/setup` installs dependencies, prepares the database, clears old logs and
temp files, and starts the development environment through `bin/dev`.

## Testing

```bash
bin/rails test
```

## Docker Compose

This repository also includes a `docker-compose.yml` for running the app
locally with the production-oriented `Dockerfile`.

1. Make sure the provided `config/master.key` file is present.

2. Export the required environment variable:

```bash
export RAILS_MASTER_KEY="$(cat config/master.key)"
```

3. Build and start the stack:

```bash
docker compose up --build
```

4. Open the app:

- App: `http://localhost:3000`
- Health check: `http://localhost:3000/up`

5. Run the stack in the background if you prefer:

```bash
docker compose up --build -d
```

6. Inspect logs:

```bash
docker compose logs -f web
docker compose logs -f db
```

7. Stop the stack:

```bash
docker compose down
```

8. Stop the stack and remove the Postgres volume:

```bash
docker compose down -v
```

Notes for the Docker setup:

- The compose file uses the production-style `Dockerfile`.
- The web container runs `bin/rails db:prepare` before booting the app.
- PostgreSQL is provided by the `db` service; Redis is not required.

## Notes

- External HTTP integrations are isolated in service objects.
- Weather data is cached by ZIP code for 30 minutes.
- Tests stub external APIs and do not require live network calls.
