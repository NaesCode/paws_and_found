# Supabase Schema & Local Development Guide

This directory houses the **database schema migrations**, RLS security policies, RPC functions, and configuration for **Paws and Found**.

The database runs managed PostgreSQL with PostGIS on **Supabase Cloud**. This repository utilizes the Supabase CLI (`npx supabase`) as the **single source of truth** for database migrations.

---

## 1. Prerequisites

* **Docker Desktop** must be running if you run the local Supabase stack.
* Node.js / `npx` (already available). You do not need to install the CLI globally; `npx supabase <command>` works everywhere.

---

## 2. Common CLI Commands

All commands are run from the repository root:

### Start the local stack
Starts local Postgres + PostGIS, GoTrue Auth, Storage, and Supabase Studio:
```bash
npx supabase start
```

### Check status & ports
Outputs API URL, GraphQL URL, DB URL, Studio URL, and anon/service keys:
```bash
npx supabase status
```

### Reset local database
Applies all migrations from `supabase/migrations/` in order and executes `supabase/seed.sql`:
```bash
npx supabase db reset
```

### Access Supabase Studio (Web UI)
By default, the local Supabase dashboard opens at:
```text
http://127.0.0.1:54323
```

### Stop the local stack
```bash
npx supabase stop
```

---

## 3. Schema Workflow (for Schema Owners)

1. **Create a new migration:**
   ```bash
   npx supabase migration new <descriptive_name>
   ```
   This generates a timestamped `.sql` file in `supabase/migrations/`.

2. **Test locally:**
   ```bash
   npx supabase db reset
   ```

3. **Deploy to Supabase Cloud:**
   ```bash
   npx supabase login
   npx supabase link --project-ref <PROJECT_REF>
   npx supabase db push
   ```

