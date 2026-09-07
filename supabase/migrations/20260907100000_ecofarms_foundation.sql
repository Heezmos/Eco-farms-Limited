-- Ecofarms shared digital foundation
-- Public website submissions and authenticated management operations.

create extension if not exists pgcrypto;
create schema if not exists app_private;

create table public.eco_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 120),
  role text not null default 'viewer' check (role in ('superuser', 'admin', 'manager', 'operations', 'field_officer', 'finance', 'commercial', 'viewer')),
  department text,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.eco_products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  category text not null check (category in ('eggs', 'poultry', 'vegetable', 'grain', 'root_crop', 'oil', 'other')),
  sourcing_identity text not null check (sourcing_identity in ('ecofarms_grown', 'ecofarms_partner', 'ecofarms_verified')),
  unit text not null check (char_length(unit) between 1 and 40),
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name, sourcing_identity)
);

create table public.eco_farmer_applications (
  id uuid primary key default gen_random_uuid(),
  reference_number text not null unique default ('EFA-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  full_name text not null check (char_length(full_name) between 2 and 120),
  phone text not null check (char_length(phone) between 7 and 30),
  email text check (email is null or char_length(email) <= 254),
  district text not null check (char_length(district) between 2 and 80),
  chiefdom text check (chiefdom is null or char_length(chiefdom) <= 100),
  community text check (community is null or char_length(community) <= 120),
  farm_size_hectares numeric(10,2) check (farm_size_hectares is null or farm_size_hectares >= 0),
  primary_products text[] not null default '{}',
  experience_years integer check (experience_years is null or experience_years between 0 and 80),
  notes text check (notes is null or char_length(notes) <= 3000),
  status text not null default 'new' check (status in ('new', 'reviewing', 'verification', 'approved', 'declined', 'converted')),
  assigned_to uuid references public.eco_profiles(id) on delete set null,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.eco_farmers (
  id uuid primary key default gen_random_uuid(),
  farmer_code text not null unique,
  full_name text not null check (char_length(full_name) between 2 and 120),
  phone text not null check (char_length(phone) between 7 and 30),
  email text check (email is null or char_length(email) <= 254),
  district text not null,
  chiefdom text,
  community text,
  tier text not null default 'registered' check (tier in ('registered', 'production_partner', 'contract_farmer')),
  status text not null default 'active' check (status in ('pending', 'active', 'suspended', 'inactive')),
  joined_at date not null default current_date,
  source_application_id uuid unique references public.eco_farmer_applications(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.eco_farms (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null references public.eco_farmers(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 120),
  district text not null,
  chiefdom text,
  community text,
  total_area_hectares numeric(10,2) check (total_area_hectares is null or total_area_hectares >= 0),
  latitude numeric(9,6) check (latitude is null or latitude between -90 and 90),
  longitude numeric(9,6) check (longitude is null or longitude between -180 and 180),
  water_source text,
  verification_status text not null default 'pending' check (verification_status in ('pending', 'verified', 'rejected', 'review_due')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.eco_buyers (
  id uuid primary key default gen_random_uuid(),
  organization_name text not null check (char_length(organization_name) between 2 and 160),
  contact_name text not null check (char_length(contact_name) between 2 and 120),
  phone text not null check (char_length(phone) between 7 and 30),
  email text check (email is null or char_length(email) <= 254),
  segment text not null check (segment in ('hotel_restaurant_caterer', 'supermarket_retailer', 'wholesaler_processor', 'institution', 'household', 'other')),
  location text,
  payment_terms text not null default 'prepaid' check (payment_terms in ('prepaid', 'cash_on_delivery', 'credit_7', 'credit_14', 'credit_30', 'custom')),
  status text not null default 'prospect' check (status in ('prospect', 'trial', 'active', 'inactive', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.eco_supply_requests (
  id uuid primary key default gen_random_uuid(),
  reference_number text not null unique default ('ESR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  organization_name text not null check (char_length(organization_name) between 2 and 160),
  contact_name text not null check (char_length(contact_name) between 2 and 120),
  phone text not null check (char_length(phone) between 7 and 30),
  email text check (email is null or char_length(email) <= 254),
  buyer_segment text not null check (buyer_segment in ('hotel_restaurant_caterer', 'supermarket_retailer', 'wholesaler_processor', 'institution', 'household', 'other')),
  delivery_location text not null check (char_length(delivery_location) between 2 and 240),
  requested_items jsonb not null default '[]'::jsonb check (jsonb_typeof(requested_items) = 'array'),
  frequency text not null default 'one_time' check (frequency in ('one_time', 'weekly', 'fortnightly', 'monthly', 'custom')),
  required_from date,
  notes text check (notes is null or char_length(notes) <= 3000),
  status text not null default 'new' check (status in ('new', 'qualifying', 'quoted', 'approved', 'fulfilled', 'declined', 'cancelled')),
  assigned_to uuid references public.eco_profiles(id) on delete set null,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index eco_farmer_applications_status_submitted_idx on public.eco_farmer_applications (status, submitted_at desc);
create index eco_farmer_applications_assigned_idx on public.eco_farmer_applications (assigned_to) where assigned_to is not null;
create index eco_farmers_status_tier_idx on public.eco_farmers (status, tier);
create index eco_farms_farmer_idx on public.eco_farms (farmer_id);
create index eco_farms_verification_idx on public.eco_farms (verification_status);
create index eco_buyers_status_segment_idx on public.eco_buyers (status, segment);
create index eco_supply_requests_status_submitted_idx on public.eco_supply_requests (status, submitted_at desc);
create index eco_supply_requests_assigned_idx on public.eco_supply_requests (assigned_to) where assigned_to is not null;
create index eco_supply_requests_items_gin_idx on public.eco_supply_requests using gin (requested_items);

create or replace function app_private.current_ecofarms_role()
returns text
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select role
  from public.eco_profiles
  where id = (select auth.uid()) and is_active = true
$$;

revoke all on function app_private.current_ecofarms_role() from public, anon;
grant execute on function app_private.current_ecofarms_role() to authenticated;

create or replace function public.eco_set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.eco_set_updated_at() from public, anon, authenticated;

create trigger eco_profiles_updated before update on public.eco_profiles for each row execute function public.eco_set_updated_at();
create trigger eco_products_updated before update on public.eco_products for each row execute function public.eco_set_updated_at();
create trigger eco_farmer_applications_updated before update on public.eco_farmer_applications for each row execute function public.eco_set_updated_at();
create trigger eco_farmers_updated before update on public.eco_farmers for each row execute function public.eco_set_updated_at();
create trigger eco_farms_updated before update on public.eco_farms for each row execute function public.eco_set_updated_at();
create trigger eco_buyers_updated before update on public.eco_buyers for each row execute function public.eco_set_updated_at();
create trigger eco_supply_requests_updated before update on public.eco_supply_requests for each row execute function public.eco_set_updated_at();

alter table public.eco_profiles enable row level security;
alter table public.eco_products enable row level security;
alter table public.eco_farmer_applications enable row level security;
alter table public.eco_farmers enable row level security;
alter table public.eco_farms enable row level security;
alter table public.eco_buyers enable row level security;
alter table public.eco_supply_requests enable row level security;

create policy eco_profiles_read on public.eco_profiles for select to authenticated
using (id = (select auth.uid()) or app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager'));
create policy eco_profiles_manage on public.eco_profiles for all to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin'));

create policy eco_products_public_read on public.eco_products for select to anon, authenticated
using (is_active = true or app_private.current_ecofarms_role() is not null);
create policy eco_products_manage on public.eco_products for all to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'));

create policy eco_farmer_applications_submit on public.eco_farmer_applications for insert to anon, authenticated
with check (status = 'new' and assigned_to is null);
create policy eco_farmer_applications_read on public.eco_farmer_applications for select to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));
create policy eco_farmer_applications_manage on public.eco_farmer_applications for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));

create policy eco_farmers_read on public.eco_farmers for select to authenticated
using (app_private.current_ecofarms_role() is not null);
create policy eco_farmers_manage on public.eco_farmers for all to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));

create policy eco_farms_read on public.eco_farms for select to authenticated
using (app_private.current_ecofarms_role() is not null);
create policy eco_farms_manage on public.eco_farms for all to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));

create policy eco_buyers_read on public.eco_buyers for select to authenticated
using (app_private.current_ecofarms_role() is not null);
create policy eco_buyers_manage on public.eco_buyers for all to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'commercial', 'finance'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'commercial', 'finance'));

create policy eco_supply_requests_submit on public.eco_supply_requests for insert to anon, authenticated
with check (status = 'new' and assigned_to is null);
create policy eco_supply_requests_read on public.eco_supply_requests for select to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial', 'finance'));
create policy eco_supply_requests_manage on public.eco_supply_requests for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'));

grant usage on schema public to anon, authenticated;
grant select on public.eco_products to anon, authenticated;
grant insert on public.eco_farmer_applications, public.eco_supply_requests to anon, authenticated;
grant select, insert, update, delete on public.eco_profiles, public.eco_products, public.eco_farmer_applications,
  public.eco_farmers, public.eco_farms, public.eco_buyers, public.eco_supply_requests to authenticated;

insert into public.eco_products (name, category, sourcing_identity, unit, description) values
  ('Fresh Eggs', 'eggs', 'ecofarms_grown', 'tray', 'Fresh table eggs from Ecofarms-managed layer production.'),
  ('Poultry', 'poultry', 'ecofarms_grown', 'bird', 'Quality poultry raised under controlled Ecofarms production standards.'),
  ('Tomatoes', 'vegetable', 'ecofarms_grown', 'kilogram', 'Fresh tomatoes supplied according to seasonal availability.'),
  ('Sweet Peppers', 'vegetable', 'ecofarms_grown', 'kilogram', 'Fresh peppers produced for household and commercial buyers.'),
  ('Cucumber', 'vegetable', 'ecofarms_grown', 'kilogram', 'Fresh cucumber for retailers, caterers and hospitality buyers.'),
  ('Leafy Vegetables', 'vegetable', 'ecofarms_grown', 'bundle', 'Fresh leafy vegetables supplied in graded bundles.');

comment on table public.eco_farmer_applications is 'Public applications to join the Ecofarms Partner Farmer Network.';
comment on table public.eco_supply_requests is 'Buyer requests for one-time or recurring agricultural supply.';
comment on table public.eco_products is 'Ecofarms catalogue with Grown, Partner and Verified sourcing identities.';
