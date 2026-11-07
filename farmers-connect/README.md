# Farmers Connect AI Operating System

Farmers Connect is an Ecofarms Limited product for agricultural firms, cooperatives, farms and aggregators. This directory is the application workspace; the repository root remains the public Ecofarms corporate website.

## Supabase architecture

The current production backend is the DVL Projects Supabase project (project ref dadjxxjqqprzlroltpra, region eu-west-2). The public Ecofarms website and Farmers Connect intentionally use this existing project rather than creating duplicate projects.

- eco_* tables support Ecofarms corporate operations and management.
- fc_* tables support Farmers Connect, with organization-scoped records and Row Level Security.
- The public corporate website reads active products through fc_public_marketplace and submits/tracks buyer requests through narrowly scoped RPC functions.
- Never place a Supabase secret/service-role key in browser code or a VITE_* variable. The publishable key in the environment example is designed for public clients.

## Live Phase 1 backend

The current Farmers Connect database foundation includes:

- Supabase email/password authentication
- Organization onboarding and memberships
- Organization-scoped farms and farmer records
- Production cycles and harvest forecasts
- Row Level Security policies for the Phase 1 tenant data

The organization membership read policy is explicitly scoped to fc_organizations.id; keep that correlation when maintaining or rebuilding the schema.

## Phase 2 modules — not yet live

Marketplace listings, buyer demand, cross-organization inquiries, orders, analytics, fulfillment, payment records and AI interactions still need their own complete database tables, RPCs, tenant-isolation policies and workflow tests. The interface must keep these modules labelled as in development until their backend is implemented and verified.

## Development rule

Build and test one workflow at a time. Verify authentication, organization isolation and the Phase 1 create/read flows before enabling commerce or AI features. Keep the corporate website's public marketplace boundary separate from private Farmers Connect organization data.
