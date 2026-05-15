# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Soldat is a Rails 7.1 application for managing solar facility data from an external SCADA system (solarpark-online.com/ifms). It fetches, stores, and exposes hierarchical measurement data across organizations, sites, segments, measurement locations, and measurements/events.

## Commands

```bash
# Install dependencies
bundle install && npm install

# Database
rails db:create && rails db:migrate

# Run server (port 5000 by default)
bin/rails server

# Run Sidekiq worker (required for background jobs)
bundle exec sidekiq -c 5

# Run all tests
bundle exec rspec

# Run a single test file
bundle exec rspec spec/models/scada_site_spec.rb

# Run a single example by line number
bundle exec rspec spec/jobs/run_daily_data_services_job_spec.rb:42

# Update crontab from schedule.rb
whenever --update-crontab
```

## Architecture

### Data Hierarchy

The core domain maps directly to the external SCADA API's structure:

```
ScadaOrganization
  └─> ScadaSite
        └─> ScadaSegment
              └─> ScadaMloc (measurement location)
                    └─> ScadaMeasurement
                          └─> ScadaMeasurementSource
                                └─> ScadaEvent
```

### External API Integration (`app/services/pf/`)

`Pf::BaseApiService` is the HTTP client for the SCADA API. Each level of the hierarchy has a corresponding service class (`Pf::SiteDataService`, `Pf::SegmentDataService`, `Pf::MlocDataService`, `Pf::MeasurementDataService`, `Pf::EventDataService`) that fetches from the API and persists to the database.

### Background Jobs (`app/jobs/`)

- `RunDailyDataServicesJob` — runs at 12:05 AM daily (via `config/schedule.rb` + whenever gem), orchestrates the full data sync
- `GetPowerfactorsDataJob` — runs at midnight (via `config/sidekiq.yml` sidekiq-cron), fetches event data
- Other import jobs handle one-off data loading tasks

Sidekiq requires Redis. Connection configured in `config/initializers/sidekiq.rb`.

### API vs. Web Routes

Two distinct surfaces in `config/routes.rb`:

- **Web UI** (`/`, `/projects`, `/pvsysts`, `/pvsyst_simulations`, `/imports`) — Hotwire (Turbo + Stimulus) with Bootstrap and Tabulator for tables
- **REST API** (`/api/v1/...`) — nested resources mirroring the SCADA hierarchy, entry point via `POST /api/v1/scada_events`

### PVsyst Integration

Separate from the SCADA hierarchy: `Project` → `Pvsyst` → `PvsystSimulation` models handle PVsyst simulation data imports (Excel parsing via caxlsx/rubyzip).

### Database

PostgreSQL in production (AWS RDS), SQLite3 in development/test. `FieldAlias` and `ApiClient` models support configurable field name mapping and API authentication.

### Testing

RSpec with VCR cassettes for HTTP interactions (`spec/vcr/`). Capybara + Selenium for integration tests. Test fixtures in `spec/factories/` or `spec/fixtures/`.

### Scripts

`scripts/` contains ~33 standalone Ruby scripts for one-off data manipulation, exports, and investigation — not part of the Rails app load path.

## Key Environment Variables

- `SCADA_API_KEY` — authenticates requests to the SCADA API
- `DATABASE_PASSWORD` — PostgreSQL password (production)
- `REDIS_URL` — Sidekiq backend
