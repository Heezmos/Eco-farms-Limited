# Farmers Connect AI Operating System

Farmers Connect is an Ecofarms Limited product for agricultural firms, cooperatives, farms and aggregators. This directory is the real application workspace; the root Eco-farms-Limited site remains the public corporate website.

## Current milestone
Phase 1 application shell created from the approved prototype direction: organization context, responsive navigation, farm/harvest/market/order/AI modules and onboarding flow. UI labels that are not yet backed by Supabase are intentionally presented as Phase 1 modules rather than live capabilities.

## Architecture
Use a dedicated Farmers Connect Supabase project. Multi-tenant records must be scoped by organization_id and protected by tested Row Level Security. Ecofarms Management Hub remains a separate private application. Corporate-site syndication must be opt-in and API-controlled.

## Next implementation gate
Connect Supabase, run the Phase 1 migration, implement organization onboarding/auth/memberships, then make Farms and Production persistent. Do not enable marketplace transactions until tenant-isolation and inventory-consistency tests pass.
