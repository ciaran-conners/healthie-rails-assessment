# Providers, Clients & Journal Entries

A Rails data model for providers (e.g. dietitians), their clients, and client health journal entries.

## Running it

Requires Docker.

```bash
docker compose up -d                          # starts Postgres + Rails (migrates on boot)
docker compose exec web bin/rails db:seed     # sample data (safe to re-run)
docker compose exec web bin/rails console
```

The app is served on [localhost:3001](http://localhost:3001/up). Opening the folder in VS Code with the Dev Containers extension ("Reopen in Container") gives a shell, Ruby LSP, and RuboCop inside the `web` container, so the `docker compose exec web` prefix can be dropped.

Lint with `bin/rubocop`.

## Data model

```
providers ──< subscriptions >── clients ──< journal_entries
```

| Table | Columns | Constraints |
|---|---|---|
| `providers` | `name`, `email` | both required; `email` unique |
| `clients` | `name`, `email` | both required; `email` unique |
| `subscriptions` | `provider_id`, `client_id`, `plan` | `plan` is `basic` or `premium` (default `basic`); unique on `[provider_id, client_id]` |
| `journal_entries` | `client_id`, `body` (text) | `body` required |

- **Providers ↔ clients is many-to-many** through `subscriptions`, a join table with its own model.
- **The plan lives on the subscription**, not on the provider or client: a client has one plan *per provider* they're signed up with, so the same client can be premium with one provider and basic with another.
- **Journal entries belong to the client.** Every provider a client is signed up with can see that client's entries; an entry isn't tied to any one provider.
- Rules are enforced in both places: model validations for readable errors, database constraints (`NOT NULL`, unique indexes, foreign keys) as the guarantee against bypassed validations and race conditions.

## Queries

```ruby
provider = Provider.find_by(email: "ada@example.com")
client   = Client.find_by(email: "cam@example.com")

# All clients for a given provider
provider.clients

# All providers for a given client
client.providers

# All journal entries for a given client, sorted by date
client.journal_entries.chronological

# All journal entries across all clients of a given provider, sorted by date
provider.journal_entries.chronological
```

To run all four against the seed data:

```bash
docker compose exec web bin/rails runner script/queries.rb
```

`chronological` is a scope on `JournalEntry` that sorts newest first by default (`created_at DESC`, with `id` as a tiebreaker); pass `:asc` for oldest first, e.g. `client.journal_entries.chronological(:asc)`. Each query runs as a single SQL statement; append `.to_sql` to see the joins.

The first two come straight from the `has_many :through` associations. The last one chains through two joins (providers → subscriptions → clients → journal_entries) via `Provider has_many :journal_entries, through: :clients`. Written out explicitly, it's equivalent to:

```ruby
JournalEntry.joins(client: :subscriptions)
            .where(subscriptions: { provider_id: provider.id })
            .chronological
```

The unique `[provider_id, client_id]` index guarantees a client appears at most once per provider, so this never returns duplicate entries.

### Expected results with the seed data

Ada has Cam (premium) and Dee (basic); Bo has Cam (basic).

| Query | Result |
|---|---|
| `ada.clients` | Cam, Dee |
| `cam.providers` | Dr. Ada, Dr. Bo |
| `cam.journal_entries.chronological` | Skipped lunch, Ate oatmeal |
| `ada.journal_entries.chronological` | Skipped lunch, Went for a run, Ate oatmeal |
| `bo.journal_entries.chronological` | Skipped lunch, Ate oatmeal |

## Assumptions & possible extensions

- **"Sorted by date"** uses when the entry was posted (`created_at`), newest first. If entries describe a specific day that can differ from when they were written, add an `entry_date` column and sort on that.
- **Plan-gated access:** if only premium clients' journals should be visible to a provider, filter query 4 with `.where(subscriptions: { plan: "premium" })`.
- **Provider-authored entries:** keep `client_id` as "whose journal" and add a polymorphic `author` (Client or Provider).
- **At scale:** add a composite index on `journal_entries [client_id, created_at]`, paginate with a limit and keyset cursors, use `includes(:client)` to avoid N+1s, and measure with `EXPLAIN ANALYZE` before considering a denormalized per-provider feed table for query 4.
