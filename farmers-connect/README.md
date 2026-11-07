# Farmers Connect AI Operating System

Farmers Connect is an Ecofarms Limited product for agricultural firms, cooperatives, farms and aggregators. This directory is the application workspace; the repository root remains the public Ecofarms corporate website.

## Supabase architecture

The production backend is the DVL Projects Supabase project (project ref `dadjxxjqqprzlroltpra`, region `eu-west-2`). The public Ecofarms website and Farmers Connect intentionally share this existing project rather than creating duplicate projects.

- `eco_*` tables support Ecofarms corporate operations and its public catalogue.
- `fc_*` tables support Farmers Connect, with organization-scoped records and Row Level Security.
- The public Ecofarms website reads the Ecofarms catalogue and published Farmers Connect listings through `fc_public_marketplace`.
- Public buyer requests for Farmers Connect listings become organization-scoped `fc_public_inquiries`; existing Ecofarms catalogue enquiries keep their current supply-request workflow.
- Never place a Supabase secret/service-role key in browser code or a `VITE_*` variable. The publishable key in the environment example is designed for public clients.

## Live backend

- Supabase email/password authentication and organization onboarding
- Organization memberships and tenant-isolated farm, farmer, production and harvest records
- Marketplace listings and buyer demand
- Supply/demand matching within an organization
- Order and reservation workflows with guarded status transitions
- Public marketplace inquiries and tracking
- Delivery and payment record capture
- Organization-scoped AI context and interaction history

## Rollout notes

The commerce schema and application modules are deployed, but the project currently has no Farmers Connect organization or operational commerce records. The first organization must be registered through the app before listings and orders can be created. Notification events are queued for operational follow-up; no SMS/email provider is configured yet. Payment entries are records only and do not process money.

## Security

All Farmers Connect business tables have Row Level Security. Membership checks scope records to the signed-in user's active organization. Public website RPCs expose only published product fields, validate incoming requests and require the buyer's tracking reference plus matching contact detail for tracking.

## Development rule

Test each workflow using a real organization account before describing it as operational. Keep payment processing, outbound messaging and AI-generated advice separate from simple record capture until their providers, controls and testing are completed.
