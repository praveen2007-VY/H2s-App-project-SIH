-- H₂S Safety Platform — Supabase/PostgreSQL foundation
create extension if not exists pgcrypto;

create table if not exists organizations (id uuid primary key default gen_random_uuid(), name text not null, created_at timestamptz default now());
create table if not exists roles (id uuid primary key default gen_random_uuid(), name text unique not null);
create table if not exists permissions (id uuid primary key default gen_random_uuid(), name text unique not null);
create table if not exists users (id uuid primary key, organization_id uuid references organizations(id), employee_id text unique, full_name text, email text, phone text, created_at timestamptz default now());
create table if not exists user_roles (user_id uuid references users(id) on delete cascade, role_id uuid references roles(id) on delete cascade, primary key(user_id, role_id));
create table if not exists sites (id uuid primary key default gen_random_uuid(), organization_id uuid references organizations(id) on delete cascade, name text not null);
create table if not exists zones (id uuid primary key default gen_random_uuid(), site_id uuid references sites(id) on delete cascade, name text not null, safe_min numeric, warning_min numeric, critical_min numeric);
create table if not exists workers (id uuid primary key default gen_random_uuid(), user_id uuid references users(id) on delete cascade, organization_id uuid references organizations(id), site_id uuid references sites(id), status text default 'active');
create table if not exists worker_assignments (id uuid primary key default gen_random_uuid(), worker_id uuid references workers(id) on delete cascade, zone_id uuid references zones(id));
create table if not exists devices (id uuid primary key default gen_random_uuid(), serial_number text unique not null, status text default 'offline', battery numeric, firmware text, last_sync_at timestamptz);
create table if not exists device_assignments (id uuid primary key default gen_random_uuid(), device_id uuid references devices(id) on delete cascade, worker_id uuid references workers(id) on delete cascade, assigned_at timestamptz default now());
create table if not exists device_events (id uuid primary key default gen_random_uuid(), device_id uuid references devices(id) on delete cascade, event_type text, payload jsonb, created_at timestamptz default now());
create table if not exists scans (id uuid primary key default gen_random_uuid(), worker_id uuid references workers(id), device_id uuid references devices(id), organization_id uuid references organizations(id), site_id uuid references sites(id), zone_id uuid references zones(id), captured_at timestamptz not null default now(), image_url text, exposure_index numeric, risk_level text, confidence numeric, model_version text, calibration_version text, latitude double precision, longitude double precision, gps_accuracy numeric, image_quality numeric, lighting_quality numeric, notes text, created_at timestamptz default now(), updated_at timestamptz default now());
create table if not exists scan_images (id uuid primary key default gen_random_uuid(), scan_id uuid references scans(id) on delete cascade, storage_path text, metadata jsonb, created_at timestamptz default now());
create table if not exists scan_color_values (id uuid primary key default gen_random_uuid(), scan_id uuid references scans(id) on delete cascade, red numeric, green numeric, blue numeric, hue numeric, saturation numeric, value numeric, lab_l numeric, lab_a numeric, lab_b numeric, delta_e numeric);
create table if not exists exposure_predictions (id uuid primary key default gen_random_uuid(), scan_id uuid references scans(id) on delete cascade, exposure_index numeric, risk_level text, confidence numeric, model_version text, calibration_version text, created_at timestamptz default now());
create table if not exists locations (id uuid primary key default gen_random_uuid(), worker_id uuid references workers(id), site_id uuid references sites(id), zone_id uuid references zones(id), latitude double precision not null, longitude double precision not null, accuracy numeric, source text, captured_at timestamptz default now());
create table if not exists location_events (id uuid primary key default gen_random_uuid(), location_id uuid references locations(id) on delete cascade, event_type text, payload jsonb, created_at timestamptz default now());
create table if not exists alerts (id uuid primary key default gen_random_uuid(), scan_id uuid references scans(id), worker_id uuid references workers(id), severity text not null, status text default 'open', title text, message text, created_at timestamptz default now(), acknowledged_at timestamptz);
create table if not exists alert_events (id uuid primary key default gen_random_uuid(), alert_id uuid references alerts(id) on delete cascade, event_type text, actor_user_id uuid, payload jsonb, created_at timestamptz default now());
create table if not exists notifications (id uuid primary key default gen_random_uuid(), user_id uuid references users(id), alert_id uuid references alerts(id), channel text, title text, body text, delivered_at timestamptz, read_at timestamptz, created_at timestamptz default now());
create table if not exists reports (id uuid primary key default gen_random_uuid(), organization_id uuid references organizations(id), requested_by uuid references users(id), report_type text, filters jsonb, status text default 'queued', created_at timestamptz default now());
create table if not exists report_exports (id uuid primary key default gen_random_uuid(), report_id uuid references reports(id) on delete cascade, format text, storage_path text, created_at timestamptz default now());
create table if not exists calibration_datasets (id uuid primary key default gen_random_uuid(), organization_id uuid references organizations(id), name text, description text, created_at timestamptz default now());
create table if not exists calibration_samples (id uuid primary key default gen_random_uuid(), dataset_id uuid references calibration_datasets(id) on delete cascade, sample_label text, reference_value numeric, image_storage_path text, rgb jsonb, hsv jsonb, lab jsonb, created_at timestamptz default now());
create table if not exists model_versions (id uuid primary key default gen_random_uuid(), name text, version text unique, status text, calibration_dataset_id uuid references calibration_datasets(id), metrics jsonb, created_at timestamptz default now());
create table if not exists audit_logs (id uuid primary key default gen_random_uuid(), organization_id uuid references organizations(id), actor_user_id uuid references users(id), action text, entity_type text, entity_id uuid, payload jsonb, created_at timestamptz default now());
create table if not exists system_settings (key text primary key, value jsonb, updated_at timestamptz default now());

insert into roles(name) values ('Worker'),('Supervisor'),('Manager'),('Safety Admin'),('System Admin') on conflict do nothing;

-- Storage buckets to configure in Supabase Storage:
-- scan-images, profile-images, report-files, device-files

-- Production RLS policies must be added before deployment. Recommended access:
-- Worker -> own scans/alerts/locations; Supervisor -> assigned workers; Manager/Safety Admin -> organization scope; System Admin -> platform scope.
