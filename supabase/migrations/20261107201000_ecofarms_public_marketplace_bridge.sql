-- Public Ecofarms catalogue and buyer request bridge on DVL Projects
create index if not exists eco_supply_requests_phone_ref_idx on public.eco_supply_requests(phone,reference_number);
create index if not exists eco_supply_requests_email_ref_idx on public.eco_supply_requests(email,reference_number);
create index if not exists eco_inventory_items_product_idx on public.eco_inventory_items(product_id) where status='active';

create or replace function public.fc_public_marketplace()
returns table(id uuid,product_name text,category text,variety text,description text,unit_price numeric,currency text,quantity_unit text,available_quantity numeric,availability_type text,image_url text,verification_badge text,seller_name text,location text)
language sql stable security invoker set search_path=''
as $$
 select p.id,p.name,p.category,null::text,p.description,p.public_price,'SLE'::text,p.unit,
 nullif(coalesce((select sum(i.current_quantity) from public.eco_inventory_items i where i.product_id=p.id and i.status='active'),0),0)::numeric,
 case when p.availability_status in ('preorder','upcoming_harvest') then 'upcoming_harvest'
 when coalesce((select sum(i.current_quantity) from public.eco_inventory_items i where i.product_id=p.id and i.status='active'),0)>0 then 'in_stock' else 'on_request' end,
 p.image_url,'Ecofarms catalogue'::text,'Ecofarms Limited'::text,'Sierra Leone'::text
 from public.eco_products p where p.is_active=true order by p.is_featured desc,p.name asc;
$$;
revoke all on function public.fc_public_marketplace() from public;
grant execute on function public.fc_public_marketplace() to anon,authenticated;

create or replace function app_private.fc_submit_marketplace_inquiry_receipt_private(p_listing_id uuid,p_name text,p_phone text,p_email text,p_quantity numeric,p_fulfillment text,p_location text)
returns text language plpgsql security definer set search_path=pg_catalog,public
as $$
declare product_row record; ref text; clean_name text; clean_phone text; clean_location text;
begin
 clean_name:=trim(coalesce(p_name,'')); clean_phone:=trim(coalesce(p_phone,'')); clean_location:=trim(coalesce(p_location,''));
 if length(clean_name)<2 or length(clean_name)>120 then raise exception 'Please enter your full name'; end if;
 if length(clean_phone)<7 or length(clean_phone)>30 then raise exception 'Please enter a valid phone number'; end if;
 if p_quantity is null or p_quantity<=0 then raise exception 'Quantity must be greater than zero'; end if;
 if p_fulfillment not in ('delivery','pickup') then raise exception 'Choose delivery or pickup'; end if;
 select id,name,unit,minimum_order_quantity into product_row from public.eco_products where id=p_listing_id and is_active=true;
 if not found then raise exception 'This product is no longer available'; end if;
 if p_quantity<product_row.minimum_order_quantity then raise exception 'Minimum order quantity is % %',product_row.minimum_order_quantity,product_row.unit; end if;
 insert into public.eco_supply_requests(organization_name,contact_name,phone,email,buyer_segment,delivery_location,requested_items,frequency,notes)
 values(clean_name,clean_name,clean_phone,nullif(trim(coalesce(p_email,'')),''),'other',
 case when length(clean_location)>=2 then clean_location else 'To be confirmed' end,
 jsonb_build_array(jsonb_build_object('product_id',product_row.id,'product_name',product_row.name,'quantity',p_quantity,'unit',product_row.unit)),
 'one_time','Public website enquiry. Fulfilment preference: '||p_fulfillment) returning reference_number into ref;
 return ref;
end; $$;
revoke all on function app_private.fc_submit_marketplace_inquiry_receipt_private(uuid,text,text,text,numeric,text,text) from public;
grant usage on schema app_private to anon,authenticated;
grant execute on function app_private.fc_submit_marketplace_inquiry_receipt_private(uuid,text,text,text,numeric,text,text) to anon,authenticated;

create or replace function public.fc_submit_marketplace_inquiry_receipt(p_listing_id uuid,p_name text,p_phone text,p_email text,p_quantity numeric,p_fulfillment text,p_location text)
returns text language sql security invoker set search_path=''
as $$ select app_private.fc_submit_marketplace_inquiry_receipt_private(p_listing_id,p_name,p_phone,p_email,p_quantity,p_fulfillment,p_location); $$;
revoke all on function public.fc_submit_marketplace_inquiry_receipt(uuid,text,text,text,numeric,text,text) from public;
grant execute on function public.fc_submit_marketplace_inquiry_receipt(uuid,text,text,text,numeric,text,text) to anon,authenticated;

create or replace function app_private.fc_track_public_order_private(p_tracking_code text,p_contact text)
returns table(tracking_code text,product_name text,quantity numeric,quantity_unit text,order_status text,inquiry_status text,customer_name text,delivery_location text,fulfillment_preference text,seller_name text,currency text,total_amount numeric,unit_price numeric)
language sql stable security definer set search_path=pg_catalog,public
as $$
 select r.reference_number,coalesce(r.requested_items->0->>'product_name','Supply request'),
 nullif(r.requested_items->0->>'quantity','')::numeric,coalesce(r.requested_items->0->>'unit','unit'),
 case r.status when 'new' then 'submitted' when 'qualifying' then 'submitted' when 'quoted' then 'quoted' when 'approved' then 'reserved' when 'fulfilled' then 'completed' else r.status end,
 r.status,r.contact_name,r.delivery_location,coalesce(nullif(split_part(r.notes,'Fulfilment preference: ',2),''),'To be confirmed'),
 'Ecofarms Limited','SLE',null::numeric,null::numeric
 from public.eco_supply_requests r where upper(r.reference_number)=upper(trim(coalesce(p_tracking_code,'')))
 and (regexp_replace(r.phone,'[^0-9]','','g')=regexp_replace(coalesce(p_contact,''),'[^0-9]','','g') or lower(coalesce(r.email,''))=lower(trim(coalesce(p_contact,''))))
 and length(trim(coalesce(p_contact,'')))>=5 limit 1;
$$;
revoke all on function app_private.fc_track_public_order_private(text,text) from public,anon,authenticated;
grant execute on function app_private.fc_track_public_order_private(text,text) to anon,authenticated;
create or replace function public.fc_track_public_order(p_tracking_code text,p_contact text)
returns table(tracking_code text,product_name text,quantity numeric,quantity_unit text,order_status text,inquiry_status text,customer_name text,delivery_location text,fulfillment_preference text,seller_name text,currency text,total_amount numeric,unit_price numeric)
language sql stable security invoker set search_path=''
as $$ select * from app_private.fc_track_public_order_private(p_tracking_code,p_contact); $$;
revoke all on function public.fc_track_public_order(text,text) from public;
grant execute on function public.fc_track_public_order(text,text) to anon,authenticated;
