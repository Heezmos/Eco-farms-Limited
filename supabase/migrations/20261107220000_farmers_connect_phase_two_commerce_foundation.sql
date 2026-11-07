-- Farmers Connect Phase 2 commerce foundation
-- Tenant-isolated supply, demand, order, inquiry, delivery, payment and AI context records.
create table if not exists public.fc_listings (
 id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 created_by uuid not null references auth.users(id), product_name text not null check(length(trim(product_name)) between 2 and 160),
 category text,variety text,description text,image_url text,available_quantity numeric(14,2) not null check(available_quantity>0),
 reserved_quantity numeric(14,2) not null default 0 check(reserved_quantity>=0 and reserved_quantity<=available_quantity),
 quantity_unit text not null default 'kg',unit_price numeric(14,2) check(unit_price is null or unit_price>=0),
 currency text not null default 'SLE',availability_type text not null default 'in_stock' check(availability_type in('in_stock','upcoming_harvest','on_request')),
 available_from date,location text,status text not null default 'draft' check(status in('draft','published','paused','sold_out','archived')),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.fc_buyer_demands (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 created_by uuid not null references auth.users(id),product_name text not null check(length(trim(product_name)) between 2 and 160),
 buyer_name text not null,buyer_contact text,quantity numeric(14,2) not null check(quantity>0),quantity_unit text not null default 'kg',
 needed_by date,delivery_location text,status text not null default 'open' check(status in('open','matched','fulfilled','cancelled')),
 notes text,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.fc_orders (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 listing_id uuid references public.fc_listings(id) on delete set null,inquiry_id uuid,created_by uuid not null references auth.users(id),
 product_name text not null,buyer_name text not null,buyer_contact text,quantity numeric(14,2) not null check(quantity>0),
 quantity_unit text not null default 'kg',unit_price numeric(14,2) check(unit_price is null or unit_price>=0),currency text not null default 'SLE',
 transaction_type text not null default 'order' check(transaction_type in('order','reservation')),
 status text not null default 'inquiry' check(status in('inquiry','quoted','accepted','reserved','preparing','dispatched','delivered','completed','disputed','cancelled')),
 requested_delivery_date date,estimated_delivery_at timestamptz,delivery_location text,
 tracking_code text not null unique default('FC-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
 source text not null default 'farmers_connect' check(source in('farmers_connect','public_marketplace')),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.fc_public_inquiries (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 listing_id uuid not null references public.fc_listings(id) on delete restrict,order_id uuid,
 tracking_code text not null unique default('FCI-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
 customer_name text not null,customer_phone text not null,customer_email text,quantity numeric(14,2) not null check(quantity>0),
 quantity_unit text not null default 'kg',fulfillment_preference text not null check(fulfillment_preference in('delivery','pickup')),
 delivery_location text,status text not null default 'new' check(status in('new','accepted','declined','converted','cancelled')),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.fc_deliveries (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 order_id uuid not null references public.fc_orders(id) on delete cascade,created_by uuid not null references auth.users(id),
 destination text not null,delivery_reference text,status text not null default 'scheduled' check(status in('scheduled','in_transit','delivered','failed','cancelled')),
 delivered_at timestamptz,created_at timestamptz not null default now()
);
create table if not exists public.fc_payment_records (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 order_id uuid not null references public.fc_orders(id) on delete cascade,created_by uuid not null references auth.users(id),
 amount numeric(14,2) not null check(amount>0),currency text not null default 'SLE',payment_method text not null,
 external_reference text,status text not null default 'recorded' check(status in('recorded','verified','reversed','refunded')),created_at timestamptz not null default now()
);
create table if not exists public.fc_listing_analytics (
 listing_id uuid primary key references public.fc_listings(id) on delete cascade,organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 view_count bigint not null default 0,inquiry_count bigint not null default 0,order_count bigint not null default 0,
 units_sold numeric(14,2) not null default 0,sales_value numeric(14,2) not null default 0,updated_at timestamptz not null default now()
);
create table if not exists public.fc_customer_notifications (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 order_id uuid not null references public.fc_orders(id) on delete cascade,event_type text not null,channel text not null default 'manual_queue',
 status text not null default 'queued' check(status in('queued','sent','failed','cancelled')),payload jsonb not null default '{}'::jsonb,created_at timestamptz not null default now()
);
create table if not exists public.fc_ai_interactions (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.fc_organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id),question text not null check(length(trim(question)) between 1 and 2000),
 answer text not null,context_snapshot jsonb not null default '{}'::jsonb,created_at timestamptz not null default now()
);
create index if not exists fc_listings_org_status_created_idx on public.fc_listings(organization_id,status,created_at desc);
create index if not exists fc_demands_org_status_created_idx on public.fc_buyer_demands(organization_id,status,created_at desc);
create index if not exists fc_orders_org_status_created_idx on public.fc_orders(organization_id,status,created_at desc);
create index if not exists fc_inquiries_org_status_created_idx on public.fc_public_inquiries(organization_id,status,created_at desc);
create index if not exists fc_deliveries_org_created_idx on public.fc_deliveries(organization_id,created_at desc);
create index if not exists fc_payments_org_created_idx on public.fc_payment_records(organization_id,created_at desc);
create index if not exists fc_notifications_org_created_idx on public.fc_customer_notifications(organization_id,created_at desc);
create index if not exists fc_ai_interactions_org_created_idx on public.fc_ai_interactions(organization_id,created_at desc);
create or replace function public.fc_set_updated_at() returns trigger language plpgsql set search_path=pg_catalog as $$ begin new.updated_at:=now();return new;end $$;
do $$ declare t text;begin foreach t in array array['fc_listings','fc_buyer_demands','fc_orders','fc_public_inquiries'] loop
 execute format('drop trigger if exists %I on public.%I',t||'_set_updated_at',t);
 execute format('create trigger %I before update on public.%I for each row execute function public.fc_set_updated_at()',t||'_set_updated_at',t);
end loop;end $$;
alter table public.fc_listings enable row level security;alter table public.fc_buyer_demands enable row level security;alter table public.fc_orders enable row level security;
alter table public.fc_public_inquiries enable row level security;alter table public.fc_deliveries enable row level security;alter table public.fc_payment_records enable row level security;
alter table public.fc_listing_analytics enable row level security;alter table public.fc_customer_notifications enable row level security;alter table public.fc_ai_interactions enable row level security;
do $$ declare t text;begin foreach t in array array['fc_listings','fc_buyer_demands','fc_orders','fc_public_inquiries','fc_deliveries','fc_payment_records','fc_listing_analytics','fc_customer_notifications','fc_ai_interactions'] loop
 execute format('drop policy if exists %I on public.%I',t||'_org_member_all',t);
 execute format('create policy %I on public.%I for all to authenticated using (exists(select 1 from public.fc_memberships m where m.organization_id = %I.organization_id and m.user_id = (select auth.uid()) and m.status = ''active'')) with check (exists(select 1 from public.fc_memberships m where m.organization_id = %I.organization_id and m.user_id = (select auth.uid()) and m.status = ''active''))',t||'_org_member_all',t,t,t);
end loop;end $$;
grant select,insert,update,delete on public.fc_listings,public.fc_buyer_demands,public.fc_orders,public.fc_public_inquiries to authenticated;
grant select,insert,update on public.fc_deliveries,public.fc_payment_records,public.fc_listing_analytics,public.fc_customer_notifications,public.fc_ai_interactions to authenticated;
revoke all on public.fc_listings,public.fc_buyer_demands,public.fc_orders,public.fc_public_inquiries,public.fc_deliveries,public.fc_payment_records,public.fc_listing_analytics,public.fc_customer_notifications,public.fc_ai_interactions from anon;
create or replace view public.fc_supply_demand_matches with(security_invoker=true) as
select l.organization_id,l.id listing_id,d.id demand_id,l.product_name,l.available_quantity-l.reserved_quantity available_quantity,d.quantity demand_quantity,l.quantity_unit,
case when lower(trim(l.product_name))=lower(trim(d.product_name)) then 100 when lower(coalesce(l.category,''))=lower(trim(d.product_name)) or lower(coalesce(d.product_name,''))=lower(coalesce(l.category,'')) then 70 else 0 end match_score
from public.fc_listings l join public.fc_buyer_demands d on d.organization_id=l.organization_id
where l.status='published' and d.status='open' and l.available_quantity>l.reserved_quantity
and(lower(trim(l.product_name))=lower(trim(d.product_name)) or lower(coalesce(l.category,''))=lower(trim(d.product_name)) or lower(coalesce(d.product_name,''))=lower(coalesce(l.category,'')));
grant select on public.fc_supply_demand_matches to authenticated;
create or replace function public.fc_update_order_status(p_order_id uuid,p_new_status text) returns void language plpgsql security definer set search_path=pg_catalog,public as $$
declare o public.fc_orders;begin select * into o from public.fc_orders where id=p_order_id for update;
if not found or not exists(select 1 from public.fc_memberships m where m.organization_id=o.organization_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Order not found or access denied';end if;
if p_new_status not in('quoted','accepted','reserved','preparing','dispatched','delivered','completed','disputed','cancelled') then raise exception 'Invalid order status';end if;
if not((o.status='inquiry' and p_new_status in('quoted','cancelled'))or(o.status='quoted' and p_new_status in('accepted','cancelled'))or(o.status='accepted' and p_new_status in('reserved','preparing','cancelled'))or(o.status='reserved' and p_new_status in('preparing','cancelled'))or(o.status='preparing' and p_new_status in('dispatched','cancelled'))or(o.status='dispatched' and p_new_status in('delivered','disputed'))or(o.status='delivered' and p_new_status in('completed','disputed'))or(o.status='disputed' and p_new_status in('completed','cancelled'))) then raise exception 'Status transition not allowed';end if;
update public.fc_orders set status=p_new_status where id=p_order_id;end $$;
create or replace function public.fc_queue_customer_notification(p_order_id uuid,p_event_type text) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare o public.fc_orders;n uuid;begin select * into o from public.fc_orders where id=p_order_id;
if not found or not exists(select 1 from public.fc_memberships m where m.organization_id=o.organization_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Order not found or access denied';end if;
insert into public.fc_customer_notifications(organization_id,order_id,event_type,payload)values(o.organization_id,o.id,p_event_type,jsonb_build_object('tracking_code',o.tracking_code,'buyer_name',o.buyer_name,'status',o.status))returning id into n;return n;end $$;
create or replace function public.fc_create_reservation(p_listing_id uuid,p_buyer_name text,p_buyer_contact text,p_quantity numeric,p_delivery_location text,p_delivery_date date) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare l public.fc_listings;new_order uuid;begin select * into l from public.fc_listings where id=p_listing_id for update;
if not found or not exists(select 1 from public.fc_memberships m where m.organization_id=l.organization_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Listing not found or access denied';end if;
if p_quantity is null or p_quantity<=0 or p_quantity>(l.available_quantity-l.reserved_quantity) then raise exception 'Requested quantity exceeds available supply';end if;
insert into public.fc_orders(organization_id,listing_id,created_by,product_name,buyer_name,buyer_contact,quantity,quantity_unit,unit_price,currency,transaction_type,status,requested_delivery_date,delivery_location)
values(l.organization_id,l.id,auth.uid(),l.product_name,trim(p_buyer_name),nullif(trim(coalesce(p_buyer_contact,'')),''),p_quantity,l.quantity_unit,l.unit_price,l.currency,'reservation','reserved',p_delivery_date,p_delivery_location)returning id into new_order;
update public.fc_listings set reserved_quantity=reserved_quantity+p_quantity where id=l.id;return new_order;end $$;
create or replace function public.fc_convert_inquiry_to_order(p_inquiry_id uuid) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare i public.fc_public_inquiries;l public.fc_listings;o uuid;begin select * into i from public.fc_public_inquiries where id=p_inquiry_id for update;
if not found or not exists(select 1 from public.fc_memberships m where m.organization_id=i.organization_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Inquiry not found or access denied';end if;
if i.status<>'new' then raise exception 'Inquiry has already been processed';end if;select * into l from public.fc_listings where id=i.listing_id for update;
if not found then raise exception 'Listing no longer exists';end if;if i.quantity>(l.available_quantity-l.reserved_quantity) then raise exception 'Insufficient available supply';end if;
insert into public.fc_orders(organization_id,listing_id,inquiry_id,created_by,product_name,buyer_name,buyer_contact,quantity,quantity_unit,unit_price,currency,transaction_type,status,delivery_location,source)
values(i.organization_id,l.id,i.id,auth.uid(),l.product_name,i.customer_name,i.customer_phone,i.quantity,i.quantity_unit,l.unit_price,l.currency,'order','accepted',i.delivery_location,'public_marketplace')returning id into o;
update public.fc_listings set reserved_quantity=reserved_quantity+i.quantity where id=l.id;update public.fc_public_inquiries set status='converted',order_id=o where id=i.id;
update public.fc_listing_analytics set inquiry_count=inquiry_count+1,order_count=order_count+1,updated_at=now() where listing_id=l.id;return o;end $$;
create or replace function public.fc_record_delivery(p_order_id uuid,p_destination text,p_reference text default null) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare o public.fc_orders;d uuid;begin select * into o from public.fc_orders where id=p_order_id;
if not found or not exists(select 1 from public.fc_memberships m where m.organization_id=o.organization_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Order not found or access denied';end if;
insert into public.fc_deliveries(organization_id,order_id,created_by,destination,delivery_reference)values(o.organization_id,o.id,auth.uid(),trim(p_destination),nullif(trim(coalesce(p_reference,'')),''))returning id into d;return d;end $$;
create or replace function public.fc_record_payment(p_order_id uuid,p_amount numeric,p_method text,p_reference text default null) returns uuid language plpgsql security definer set search_path=pg_catalog,public as $$
declare o public.fc_orders;p uuid;begin select * into o from public.fc_orders where id=p_order_id;
if not found or not exists(select 1 from public.fc_memberships m where m.organization_id=o.organization_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Order not found or access denied';end if;
if p_amount is null or p_amount<=0 then raise exception 'Payment amount must be greater than zero';end if;
insert into public.fc_payment_records(organization_id,order_id,created_by,amount,currency,payment_method,external_reference)values(o.organization_id,o.id,auth.uid(),p_amount,o.currency,trim(p_method),nullif(trim(coalesce(p_reference,'')),''))returning id into p;return p;end $$;
create or replace function public.fc_ai_context(p_org_id uuid) returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public as $$
begin if not exists(select 1 from public.fc_memberships m where m.organization_id=p_org_id and m.user_id=auth.uid() and m.status='active') then raise exception 'Organization access denied';end if;
return jsonb_build_object('generated_at',now(),
'farms',(select coalesce(jsonb_agg(jsonb_build_object('name',f.name,'district',f.district,'status',f.status)),'[]'::jsonb) from public.fc_farms f where f.organization_id=p_org_id),
'farmers',(select coalesce(jsonb_agg(jsonb_build_object('name',f.full_name,'district',f.district,'status',f.status)),'[]'::jsonb) from public.fc_farmers f where f.organization_id=p_org_id),
'production',(select coalesce(jsonb_agg(jsonb_build_object('product',p.product_name,'status',p.status)),'[]'::jsonb) from public.fc_production_cycles p where p.organization_id=p_org_id),
'harvests',(select coalesce(jsonb_agg(jsonb_build_object('expected_quantity',h.expected_quantity,'unit',h.quantity_unit,'expected_harvest_date',h.expected_harvest_date,'confidence',h.confidence)),'[]'::jsonb) from public.fc_harvest_forecasts h where h.organization_id=p_org_id),
'buyer_demands',(select coalesce(jsonb_agg(jsonb_build_object('buyer',d.buyer_name,'quantity',d.quantity,'unit',d.quantity_unit,'product',d.product_name,'needed_by',d.needed_by,'status',d.status)),'[]'::jsonb) from public.fc_buyer_demands d where d.organization_id=p_org_id),
'orders',(select coalesce(jsonb_agg(jsonb_build_object('buyer',o.buyer_name,'quantity',o.quantity,'unit',o.quantity_unit,'product',o.product_name,'status',o.status)),'[]'::jsonb) from public.fc_orders o where o.organization_id=p_org_id));end $$;
revoke all on function public.fc_update_order_status(uuid,text),public.fc_queue_customer_notification(uuid,text),public.fc_create_reservation(uuid,text,text,numeric,text,date),public.fc_convert_inquiry_to_order(uuid),public.fc_record_delivery(uuid,text,text),public.fc_record_payment(uuid,numeric,text,text),public.fc_ai_context(uuid) from public,anon;
grant execute on function public.fc_update_order_status(uuid,text),public.fc_queue_customer_notification(uuid,text),public.fc_create_reservation(uuid,text,text,numeric,text,date),public.fc_convert_inquiry_to_order(uuid),public.fc_record_delivery(uuid,text,text),public.fc_record_payment(uuid,numeric,text,text),public.fc_ai_context(uuid) to authenticated;
