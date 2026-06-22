# Enthasys

Solar facility data platform for ingesting, storing, and analyzing SCADA telemetry and PVsyst simulation data. Integrates with the solarpark-online IFMS API to sync hierarchical measurement data across organizations, sites, and stations.

## Stack

| Layer | Technology |
|---|---|
| Runtime | Ruby 3.2.2 / Rails 8.0 |
| Database | PostgreSQL 14+ (AWS RDS in production) |
| Background jobs | Sidekiq 7 + Redis + sidekiq-cron |
| Cron scheduling | whenever (writes system crontab) |
| Auth | Rails 8 built-in (Session model + bcrypt) |
| Authorization | Pundit (user / admin roles) |
| Frontend | Hotwire (Turbo + Stimulus), Bootstrap 4.6, Sprockets 4 |
| Tables | Tabulator 5.5 + Luxon 3 (datetime formatting) |
| Charts | ApexCharts 3.49 |
| Search dropdowns | Tom Select 2.3 |
| PVsyst import | caxlsx + rubyzip (Excel parsing) |
| Asset pipeline | Sprockets 4 + sassc-rails |

## Prerequisites

- Ruby 3.2.2 (via rbenv or rvm)
- PostgreSQL 14+
- Redis (required for Sidekiq)
- Node.js + npm (for asset compilation)

## Local Setup

```bash
git clone <repo>
cd enthasys

bundle install
npm install

# Create and migrate the database
rails db:create db:migrate

# Seed reference data if applicable
rails db:seed
```

Copy and configure environment variables (see [Environment Variables](#environment-variables) below).

## Running the Application

```bash
# Web server (port 5000)
bin/rails server

# Sidekiq worker (required for background jobs)
bundle exec sidekiq -c 5
```

Both processes are needed for full functionality. In production, Procfile drives both:

```
release: bin/rails db:migrate
web:     bin/rails server -p ${PORT:-5000} -e $RAILS_ENV
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `SCADA_API_KEY` | Yes | API key for `portal.solarpark-online.com/ifms` |
| `DATABASE_PASSWORD` | Production | PostgreSQL password |
| `REDIS_URL` | Production | Sidekiq backend (defaults to `redis://localhost:6379`) |
| `RAILS_MASTER_KEY` | Production | Decrypts `config/credentials.yml.enc` |

## Running Tests

```bash
# Full suite
bundle exec rspec

# Single file
bundle exec rspec spec/requests/events_chart_request_spec.rb

# Single example
bundle exec rspec spec/models/scada_site_spec.rb:42
```

HTTP interactions with the SCADA API are recorded via VCR cassettes (`spec/vcr/`). Tests that exercise live API calls will require `SCADA_API_KEY` to re-record.

## Architecture

### Data Model

The domain mirrors the SCADA API's hierarchy exactly:

```
ScadaOrganization
  └── ScadaSite
        └── ScadaSegment
              └── ScadaMloc               (measurement location)
                    └── ScadaMeasurement
                          └── ScadaMeasurementSource
                                └── ScadaEvent
```

`FieldAlias` joins to `ScadaMeasurement` and provides normalized metadata (`measurement_type`, `station_type`, `station_id`, `relevance`). This is the layer that maps raw SCADA field names to human-readable labels.

`User` has a `current_scada_site` FK that controls which site's data is visible in the UI. Site scoping throughout the app follows the join chain:

```ruby
ScadaMeasurementSource
  .joins(scada_measurement: { scada_mloc: :scada_segment })
  .where(scada_segments: { site_id: uuid })
```

### SCADA API Integration (`app/services/pf/`)

`Pf::BaseApiService` is the HTTP client (`portal.solarpark-online.com/ifms`, API-Key header auth). One service class per hierarchy level handles fetching and upserting:

- `Pf::SiteDataService`
- `Pf::SegmentDataService`
- `Pf::MlocDataService`
- `Pf::MeasurementDataService`
- `Pf::EventDataService`

### Background Jobs (`app/jobs/`)

| Job | Trigger | Purpose |
|---|---|---|
| `RunDailyDataServicesJob` | whenever cron — 12:05 AM daily | Orchestrates the full hierarchy sync |
| `FetchScadaEventsDataJob` | On demand / sidekiq-cron | Fetches event data for given sites, date range, and apcodes |
| `FetchScadaMeasurementDataJob` | On demand | Syncs measurement metadata |

Crontab is managed via `config/schedule.rb`. To apply changes:

```bash
whenever --update-crontab
```

### PVsyst Integration

Separate from the SCADA hierarchy. `Project` → `Pvsyst` → `PvsystSimulation` handle PVsyst simulation data imported from Excel files. Import is done through the UI at `/imports`.

### REST API (`/api/v1/`)

Exposes the SCADA hierarchy as nested REST resources. Authentication uses `ApiClient` token lookup (not session-based). Entry point for external data pushes:

```
POST /api/v1/scada_events
```

Nested read resources follow the full hierarchy:

```
/api/v1/scada_organizations/:id/scada_sites/:id/scada_segments/:id/...
```

### Web UI

Session-authenticated. Roles: `user` and `admin` (Pundit). Key routes:

| Path | Description |
|---|---|
| `/dashboard` | Home — site selector and module navigation |
| `/events_chart` | Time-series chart for SCADA measurements (ApexCharts + Tom Select) |
| `/event_data` | Tabular SCADA event explorer by period and station |
| `/data_editor` | Inline editor for `FieldAlias#measurement_type` per measurement source |
| `/pvsysts` | PVsyst parameter summary by project |
| `/pvsyst_simulations` | Hourly PVsyst simulation output |
| `/projects` | PVsyst project metadata |
| `/imports` | Excel import for Pvsyst and PvsystSimulation records |

## Scripts

`scripts/` contains ~33 standalone Ruby scripts for one-off data exports, investigation, and bulk mutations. These are not on the Rails load path — run them directly:

```bash
ruby scripts/export_events_reshaped.rb
```

## Deployment

Deployed to a PaaS (Procfile-based). Database is AWS RDS PostgreSQL (`soldat-db.cc9wiskoew5r.us-east-1.rds.amazonaws.com`). SSL is required for all production DB connections.

Production release step (`bin/rails db:migrate`) runs automatically on deploy via the `release` Procfile entry.

## Generating an API Key

```ruby
require 'securerandom'
SecureRandom.hex(20)  # => 40-character hex string
```

Store the result in the `ApiClient` table. The `SCADA_API_KEY` env var is a separate credential used to authenticate outbound requests to the SCADA API.
