# Cloud Rails Lab

A small Rails 8 app for testing every Laravel Cloud feature with a Ruby on Rails application:
Postgres and MySQL, a second database, Valkey/Redis cache, Sidekiq jobs and cron, object storage
uploads, environment variables, and routes that fail on purpose.

Every resource is optional. With nothing attached, the app still boots and the dashboard shows each
resource as **MISSING** instead of erroring.

Based on the [Laravel Cloud Ruby deploy guide](https://cloud.laravel.com/docs/deploy-guides/ruby).

## Pages

| Path               | What it does                                                                                   |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `/`                | Dashboard: status of each resource (OK / MISSING / ERROR), boot time, hostname, memory          |
| `/notes`           | Create/list/delete notes in the primary database (`DATABASE_URL`)                              |
| `/secondary_notes` | Same, in the optional secondary database (`SECONDARY_DATABASE_URL`)                             |
| `/env`             | Shows `GREETING`'s value; every other variable is shown as set/unset only                       |
| `/cache`           | Hit counter in the Rails cache (Redis via `REDIS_URL`, otherwise per-process memory)          |
| `/jobs`            | Enqueue `SlowJob` into Sidekiq; list recent job runs, including the every-minute cron heartbeat |
| `/uploads`         | Active Storage upload/list/download/delete (Cloud bucket when attached, local disk otherwise)   |
| `/sidekiq`         | Sidekiq web UI with a Cron tab (basic auth; only mounted when `SIDEKIQ_USERNAME`/`SIDEKIQ_PASSWORD` are set) |
| `/up`              | Rails health check                                                                             |

## Laravel Cloud setup checklist

1. **Create the application** from this repository. Cloud detects Ruby from the `Gemfile`, and Ruby
   3.4 from `.ruby-version`. The lockfile already includes the `aarch64-linux` platform.
2. **Build command** (Cloud pre-fills this when it detects Propshaft; Tailwind is built as part of it):
   ```sh
   SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
   ```
3. **Deploy command** (runs before each new deployment takes traffic):
   ```sh
   bin/rails db:prepare && bin/rails db:secondary:prepare
   ```
   `db:secondary:prepare` does nothing when `SECONDARY_DATABASE_URL` is unset, so it's always safe.
4. **Start command** (from the `Procfile` `web:` line):
   ```sh
   bundle exec puma -C config/puma.rb
   ```
   `config/puma.rb` listens on `[::]:$PORT` (IPv6, which Cloud's probes need) with a single listener.
   Never run migrations here: the start command runs on every boot, scale-up and wake from scale-to-zero.
5. **Background process** for Sidekiq (jobs **and** cron):
   ```sh
   bundle exec sidekiq -C config/sidekiq.yml
   ```
   Cloud has no scheduler for Rails apps. The every-minute `HeartbeatJob` runs inside this process
   (sidekiq-cron, `config/schedule.yml`), so cron stops when this process isn't running. If the
   App cluster scales to zero, keep the worker cluster awake.
6. **Attach resources** (each one is optional):
   - **Database** (Postgres or MySQL) → `DATABASE_URL` (`postgresql://` or `mysql2://`).
   - **Cache** (Valkey or Redis) → `REDIS_URL`. `rediss://` (TLS) works.
   - **Bucket** (private, as the default disk) → `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
     `AWS_BUCKET`, `AWS_ENDPOINT_URL`, and optionally `AWS_REGION` (default `auto`).
7. **Environment variables** to add yourself:

   | Variable                  | Purpose                                                                         |
   | ------------------------- | ------------------------------------------------------------------------------- |
   | `GREETING`                | Any text. Its value is shown on `/env`                                         |
   | `SIDEKIQ_USERNAME`        | Enables `/sidekiq` (with `SIDEKIQ_PASSWORD`)                                    |
   | `SIDEKIQ_PASSWORD`        | Basic auth password for `/sidekiq`                                              |
   | `SECONDARY_DATABASE_URL`  | Optional second database (e.g. copy the `DATABASE_URL` of another environment's MySQL) |
   | `REQUIRED_SETTING`        | Leave unset to make `/require-env` fail; set it to fix it                      |
   | `RAILS_MAX_THREADS`       | Optional. Puma threads, DB pool and Sidekiq concurrency (default 3)            |
   | `WEB_CONCURRENCY`         | Optional. Puma worker processes (default 0 = single process)                    |

   Cloud already sets `SECRET_KEY_BASE`, `RAILS_ENV=production`, `RAILS_LOG_TO_STDOUT`, `PORT` and `APP_URL`.

### Postgres and MySQL side by side

`DATABASE_URL` (the primary) can be either Postgres or MySQL with no code changes. Rails picks the
adapter from the URL scheme; `config/database.yml` deliberately has no production `adapter` or `url`.

To see both at once, attach one engine as the primary and set `SECONDARY_DATABASE_URL` to the other.
The secondary connection is made at runtime in `app/models/secondary_record.rb`, **not** in
`database.yml`. Cloud would treat extra `database.yml` connections as its own (it creates databases for
`cache`/`queue`/`cable` connections), and doesn't evaluate ERB there. The `secondary_notes` table is
created with `CREATE TABLE IF NOT EXISTS` by `bin/rails db:secondary:prepare` (`lib/tasks/secondary.rake`).

### Things worth knowing (found while building this)

- **The guide's `storage.yml` breaks boot without a bucket.** Its `ENV.fetch("AWS_BUCKET")` lines
  raise `KeyError` at boot when the variables are unset (e.g. a bucket was detached), because Rails
  evaluates the whole file even if the `cloud` service isn't used. This app wraps that block in
  `<% if ENV["AWS_BUCKET"].present? %>` and falls back to the `local` service (ephemeral on Cloud).
- **No `DATABASE_URL` + no `adapter` = no boot.** Rails raises `AdapterNotSpecified` at startup. The
  production block has a fallback adapter that renders empty whenever `DATABASE_URL` is set, so
  the URL scheme still decides the adapter.
- **Solid Cache/Queue/Cable are skipped on purpose.** Their `database.yml` connections would make
  Cloud create extra databases. The cache uses Redis and jobs use Sidekiq instead.

## How to break it

| Try this                                 | Expected result                                   | What to look for                                                      |
| ---------------------------------------- | ------------------------------------------------- | --------------------------------------------------------------------- |
| `GET /boom`                              | 500 error page                                    | `RuntimeError (Boom! ...)` with stack trace in Logs                    |
| `GET /require-env`                       | 500 until `REQUIRED_SETTING` is set and redeployed | `KeyError: key not found: "REQUIRED_SETTING"` in Logs                 |
| `GET /slow?seconds=120`                  | Slow response, or a timeout from Cloud's proxy    | Where the request gets cut off; Puma itself has no request timeout    |
| `GET /memory?mb=2000`                    | On a small instance, it runs out of memory        | RSS on the dashboard; "Booted at" resets if the process restarts      |
| `GET /does-not-exist`                    | Rails' default 404 page                           | `ActionController::RoutingError` in Logs                              |
| Detach the database                      | Dashboard shows Primary database MISSING          | `/notes` shows a 503 "Resource unavailable" page, not a crash        |
| Detach the cache                         | Cache + Sidekiq MISSING; cache falls back to memory | `/cache` counter is per process; `/jobs` enqueue fails with 503       |
| Stop the Sidekiq background process      | Sidekiq card: "no Sidekiq process is running"     | Jobs pile up in "Jobs waiting"; cron heartbeats stop on `/jobs`        |
| Detach the bucket                        | Bucket MISSING; uploads go to local disk          | Uploaded files vanish after the next deploy                            |
| Wrong `SECONDARY_DATABASE_URL`           | Secondary database ERROR with the message         | Deploy command fails in `db:secondary:prepare`                        |
| Remove `SIDEKIQ_PASSWORD`                | `/sidekiq` returns 404                            | Mounted only when both credentials are set                            |
| Scale to zero, wait, reload `/`          | Slow first request                                | "Booted at" on the dashboard is just before your request (cold start) |
| Remove the `bind` line from `config/puma.rb` | Deployment should fail its startup probe      | Puma must listen on `[::]` (IPv6) on `$PORT`                           |

## Local setup

Requirements (macOS):

```sh
brew install rbenv postgresql@16 mysql valkey vips
brew services start postgresql@16
brew services start mysql
brew services start valkey
rbenv install 3.4.7
```

`.ruby-version` contains `3.4` (what Cloud expects). rbenv needs an exact version, so either run
`export RBENV_VERSION=3.4.7` in your shell or alias it: `ln -s ~/.rbenv/versions/3.4.7 ~/.rbenv/versions/3.4`.

```sh
bundle install
bin/rails db:prepare

# Optional: a MySQL secondary database
mysql -uroot -e 'CREATE DATABASE IF NOT EXISTS cloud_rails_lab_secondary'
export SECONDARY_DATABASE_URL=mysql2://root@127.0.0.1:3306/cloud_rails_lab_secondary
bin/rails db:secondary:prepare

export REDIS_URL=redis://localhost:6379/0 GREETING="Hello" SIDEKIQ_USERNAME=admin SIDEKIQ_PASSWORD=secret
bin/dev   # web (port 3000) + Tailwind watcher + Sidekiq worker, from Procfile.dev
```

Locally, the primary database comes from `config/database.yml` (Postgres) and uploads use local disk.

### Test production mode against MySQL

This mimics a Cloud deployment with MySQL attached:

```sh
mysql -uroot -e 'CREATE DATABASE IF NOT EXISTS lab_mysql'
export RAILS_ENV=production SECRET_KEY_BASE=$(openssl rand -hex 64) \
  DATABASE_URL=mysql2://root@127.0.0.1:3306/lab_mysql REDIS_URL=redis://localhost:6379/1
SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
bin/rails db:prepare && bin/rails db:secondary:prepare
bundle exec puma -C config/puma.rb          # and in another shell: bundle exec sidekiq -C config/sidekiq.yml
bin/rails assets:clobber                    # afterwards, so development doesn't serve stale assets
```

## Where things live

| File                                   | What                                                                   |
| -------------------------------------- | ---------------------------------------------------------------------- |
| `config/puma.rb`                       | IPv6 listener, threads/workers, shutdown timeouts                       |
| `Procfile`                             | `web`, `worker` and `release` commands Cloud suggests                  |
| `config/database.yml`                  | Primary database; adapter comes from `DATABASE_URL`                    |
| `app/models/secondary_record.rb`       | Runtime connection to `SECONDARY_DATABASE_URL`                         |
| `lib/tasks/secondary.rake`             | `db:secondary:prepare`                                                 |
| `config/application.rb`                | Redis cache store (memory fallback), Sidekiq as Active Job adapter     |
| `config/initializers/sidekiq.rb`       | Sidekiq Redis connection, cron schedule file, `/sidekiq` basic auth   |
| `config/schedule.yml`                  | Cron jobs (sidekiq-cron)                                               |
| `config/storage.yml`                   | `cloud` (S3) Active Storage service from the Cloud guide               |
| `app/models/resource_checks.rb`        | Dashboard status checks                                                |
| `app/controllers/break_it_controller.rb` | `/boom`, `/require-env`, `/slow`, `/memory`                          |
