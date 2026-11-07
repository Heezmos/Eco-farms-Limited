-- Harden public marketplace RPC wrappers.
-- Internal SECURITY DEFINER helpers remain in the unexposed app_private schema.
-- Only narrowly scoped wrappers are callable through the public API.
revoke usage on schema app_private from anon, authenticated;
revoke all on function app_private.fc_submit_marketplace_inquiry_receipt_private(uuid,text,text,text,numeric,text,text) from public,anon,authenticated;
revoke all on function app_private.fc_track_public_order_private(text,text) from public,anon,authenticated;

create or replace function public.fc_submit_marketplace_inquiry_receipt(
 p_listing_id uuid,p_name text,p_phone text,p_email text,p_quantity numeric,p_fulfillment text,p_location text
) returns text
language sql security definer
set search_path=pg_catalog,public,app_private
as $$
 select app_private.fc_submit_marketplace_inquiry_receipt_private(
  p_listing_id,p_name,p_phone,p_email,p_quantity,p_fulfillment,p_location
 );
$$;
revoke all on function public.fc_submit_marketplace_inquiry_receipt(uuid,text,text,text,numeric,text,text) from public;
grant execute on function public.fc_submit_marketplace_inquiry_receipt(uuid,text,text,text,numeric,text,text) to anon,authenticated;

create or replace function public.fc_track_public_order(p_tracking_code text,p_contact text)
returns table(
 tracking_code text,product_name text,quantity numeric,quantity_unit text,order_status text,
 inquiry_status text,customer_name text,delivery_location text,fulfillment_preference text,
 seller_name text,currency text,total_amount numeric,unit_price numeric
)
language sql stable security definer
set search_path=pg_catalog,public,app_private
as $$
 select * from app_private.fc_track_public_order_private(p_tracking_code,p_contact);
$$;
revoke all on function public.fc_track_public_order(text,text) from public;
grant execute on function public.fc_track_public_order(text,text) to anon,authenticated;
