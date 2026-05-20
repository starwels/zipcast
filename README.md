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

## Environment Variables

Create a local `.env` file or export these variables in your shell:

- `GOOGLE_GEOCODING_API_KEY`
- `OPEN_METEO_BASE_URL`

`OPEN_METEO_BASE_URL` defaults to `https://api.open-meteo.com` if omitted.

## Setup

```bash
bundle install
bin/rails db:prepare
bin/rails server
```

## Testing

```bash
bin/rails test
```

## Notes

- External HTTP integrations are isolated in service objects.
- Weather data is cached by ZIP code for 30 minutes.
- Tests stub external APIs and do not require live network calls.
