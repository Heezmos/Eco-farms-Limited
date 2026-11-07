-- Farmers Connect tenant foundation in DVL Projects
create extension if not exists pgcrypto;
create table if not exists public.fc_organizations (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 organization_type text not null check (organization_type in ('agribusiness','farm','cooperative','aggregator','processor')),
 country_code text not null default 'SL', status text not null default 'active' check(status in ('active','suspended','archived')),
 created_by uuid not null references auth.users(id) on delete restrict, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.fc_memberships (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade, role text not null default 'owner' check(role in ('owner','admin','manager','field_officer','commercial','finance','viewer')),
 status text not null default 'active' check(status in ('active','invited','suspended')), created_at timestamptz not null default now(), unique(organization_id,user_id)
);
create table if not exists public.fc_farms (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 name text not null, district text, community text, size_hectares numeric(12,2) check(size_hectares is null or size_hectares>=0),
 status text not null default 'active' check(status in ('active','inactive','under_review')),
 created_by uuid not null references auth.users(id) on delete restrict, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.fc_farmers (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 farm_id uuid references public.fc_farms(id) on delete set null, full_name text not null, phone text, district text, community text,
 partnership_tier text not null default 'registered' check(partnership_tier in ('registered','production_partner','contract_farmer','lead_farmer')),
 status text not null default 'active' check(status in ('active','inactive','pending_verification')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.fc_production_cycles (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 farm_id uuid not null references public.fc_farms(id) on delete restrict, farmer_id uuid references public.fc_farmers(id) on delete set null,
 product_name text not null, variety text, planting_or_start_date date, expected_harvest_date date,
 area_hectares numeric(12,2) check(area_hectares is null or area_hectares>=0), expected_quantity numeric(14,2) check(expected_quantity is null or expected_quantity>=0),
 quantity_unit text not null default 'kg', status text not null default 'active' check(status in ('planned','active','completed','cancelled')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.fc_harvest_forecasts (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 production_cycle_id uuid not null references public.fc_production_cycles(id) on delete cascade, expected_harvest_date date,
 expected_quantity numeric(14,2) not null check(expected_quantity>=0), quantity_unit text not null default 'kg',
 confidence text not null default 'farmer_declared' check(confidence in ('farmer_declared','field_verified','system_estimate')),
 notes text, created_by uuid not null references auth.users(id) on delete restrict, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists fc_memberships_user_status_idx on public.fc_memberships(user_id,status);
create index if not exists fc_farms_org_created_idx on public.fc_farms(organization_id,created_at desc);
create index if not exists fc_farmers_org_created_idx on public.fc_farmers(organization_id,created_at desc);
create index if not exists fc_production_org_created_idx on public.fc_production_cycles(organization_id,created_at desc);
create index if not exists fc_harvests_org_created_idx on public.fc_harvest_forecasts(organization_id,created_at desc);
alter table public.fc_organizations enable row level security;
alter table public.fc_memberships enable row level security;
alter table public.fc_farms enable row level security;
alter table public.fc_farmers enable row level security;
alter table public.fc_production_cycles enable row level security;
alter table public.fc_harvest_forecasts enable row level security;
create policy fc_org_select_member on public.fc_organizations for select to authenticated using(created_by=(select auth.uid()) or exists(select 1 from public.fc_memberships m where m.organization_id=id and m.user_id=(select auth.uid()) and m.status='active'));
create policy fc_org_insert_owner on public.fc_organizations for insert to authenticated with check(created_by=(select auth.uid()));
create policy fc_membership_select_self on public.fc_memberships for select to authenticated using(user_id=(select auth.uid()));
create policy fc_membership_insert_initial_owner on public.fc_memberships for insert to authenticated with check(user_id=(select auth.uid()) and role='owner' and status='active' and exists(select 1 from public.fc_organizations o where o.id=organization_id and o.created_by=(select auth.uid())));
create policy fc_farms_org_member_all on public.fc_farms for all to authenticated using(exists(select 1 from public.fc_memberships m where m.organization_id=fc_farms.organization_id and m.user_id=(select auth.uid()) and m.status='active')) with check(exists(select 1 from public.fc_memberships m where m.organization_id=fc_farms.organization_id and m.user_id=(select auth.uid()) and m.status='active') and created_by=(select auth.uid()));
create policy fc_farmers_org_member_all on public.fc_farmers for all to authenticated using(exists(select 1 from public.fc_memberships m where m.organization_id=fc_farmers.organization_id and m.user_id=(select auth.uid()) and m.status='active')) with check(exists(select 1 from public.fc_memberships m where m.organization_id=fc_farmers.organization_id and m.user_id=(select auth.uid()) and m.status='active'));
create policy fc_production_org_member_all on public.fc_production_cycles for all to authenticated using(exists(select 1 from public.fc_memberships m where m.organization_id=fc_production_cycles.organization_id and m.user_id=(select auth.uid()) and m.status='active')) with check(exists(select 1 from public.fc_memberships m where m.organization_id=fc_production_cycles.organization_id and m.user_id=(select auth.uid()) and m.status='active'));
create policy fc_harvest_org_member_all on public.fc_harvest_forecasts for all to authenticated using(exists(select 1 from public.fc_memberships m where m.organization_id=fc_harvest_forecasts.organization_id and m.user_id=(select auth.uid()) and m.status='active')) with check(exists(select 1 from public.fc_memberships m where m.organization_id=fc_harvest_forecasts.organization_id and m.user_id=(select auth.uid()) and m.status='active') and created_by=(select auth.uid()));
grant select,insert on public.fc_organizations,public.fc_memberships to authenticated;
grant select,insert,update,delete on public.fc_farms,public.fc_farmers,public.fc_production_cycles,public.fc_harvest_forecasts to authenticated;
create or replace function public.fc_bootstrap_organization(org_name text,org_slug text,org_type text,org_country text default 'SL')
returns uuid language plpgsql security invoker set search_path=''
as $$
declare new_org_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if length(trim(coalesce(org_name,'')))<2 then raise exception 'Organization name is required'; end if;
 if org_type not in ('agribusiness','farm','cooperative','aggregator','processor') then raise exception 'Invalid organization type'; end if;
 insert into public.fc_organizations(name,slug,organization_type,country_code,created_by) values(trim(org_name),lower(trim(org_slug)),org_type,upper(coalesce(nullif(trim(org_country),''),'SL')),(select auth.uid())) returning id into new_org_id;
 insert into public.fc_memberships(organization_id,user_id,role,status) values(new_org_id,(select auth.uid()),'owner','active');
 return new_org_id;
end; $$;
revoke all on function public.fc_bootstrap_organization(text,text,text,text) from public,anon;
grant execute on function public.fc_bootstrap_organization(text,text,text,text) to authenticated;
