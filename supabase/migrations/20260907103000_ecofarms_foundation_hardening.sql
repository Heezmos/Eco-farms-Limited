-- Remove Supabase default broad table privileges and avoid overlapping policies.

revoke all on table public.eco_profiles, public.eco_products, public.eco_farmer_applications,
  public.eco_farmers, public.eco_farms, public.eco_buyers, public.eco_supply_requests
  from anon, authenticated;

grant select on public.eco_products to anon, authenticated;
grant insert on public.eco_farmer_applications, public.eco_supply_requests to anon, authenticated;
grant select, insert, update, delete on public.eco_profiles, public.eco_products,
  public.eco_farmer_applications, public.eco_farmers, public.eco_farms,
  public.eco_buyers, public.eco_supply_requests to authenticated;

drop policy if exists eco_profiles_manage on public.eco_profiles;
drop policy if exists eco_products_public_read on public.eco_products;
drop policy if exists eco_products_manage on public.eco_products;
drop policy if exists eco_farmers_manage on public.eco_farmers;
drop policy if exists eco_farms_manage on public.eco_farms;
drop policy if exists eco_buyers_manage on public.eco_buyers;

create policy eco_products_public_read on public.eco_products for select to anon
using (is_active = true);
create policy eco_products_staff_read on public.eco_products for select to authenticated
using (is_active = true or app_private.current_ecofarms_role() is not null);

create policy eco_profiles_insert on public.eco_profiles for insert to authenticated
with check (app_private.current_ecofarms_role() in ('superuser', 'admin'));
create policy eco_profiles_update on public.eco_profiles for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin'));
create policy eco_profiles_delete on public.eco_profiles for delete to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'));

create policy eco_products_insert on public.eco_products for insert to authenticated
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'));
create policy eco_products_update on public.eco_products for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'commercial'));
create policy eco_products_delete on public.eco_products for delete to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'));

create policy eco_farmers_insert on public.eco_farmers for insert to authenticated
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));
create policy eco_farmers_update on public.eco_farmers for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));
create policy eco_farmers_delete on public.eco_farmers for delete to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'));

create policy eco_farms_insert on public.eco_farms for insert to authenticated
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));
create policy eco_farms_update on public.eco_farms for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'operations', 'field_officer'));
create policy eco_farms_delete on public.eco_farms for delete to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'));

create policy eco_buyers_insert on public.eco_buyers for insert to authenticated
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'commercial', 'finance'));
create policy eco_buyers_update on public.eco_buyers for update to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'commercial', 'finance'))
with check (app_private.current_ecofarms_role() in ('superuser', 'admin', 'manager', 'commercial', 'finance'));
create policy eco_buyers_delete on public.eco_buyers for delete to authenticated
using (app_private.current_ecofarms_role() in ('superuser', 'admin'));
