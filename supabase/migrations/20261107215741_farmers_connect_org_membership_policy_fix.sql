-- Correct the organization-membership correlation in the organization read policy.
drop policy if exists fc_org_select_member on public.fc_organizations;

create policy fc_org_select_member
on public.fc_organizations
for select
to authenticated
using (
  created_by = (select auth.uid())
  or exists (
    select 1
    from public.fc_memberships m
    where m.organization_id = fc_organizations.id
      and m.user_id = (select auth.uid())
      and m.status = 'active'
  )
);
