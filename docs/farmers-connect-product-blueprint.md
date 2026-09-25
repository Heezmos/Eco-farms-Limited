# Farmers Connect — Agricultural AI Operating System
Product owner: Ecofarms Limited | Product status: specification and prototype, not a production launch

## Product definition
Farmers Connect is ONE SaaS operating system licensed to multiple independent agricultural organizations (farms, cooperatives, aggregators, processors and agricultural firms). Each organization gets an isolated workspace with its own users, farms, farmers, production, stock, buyers, orders, finance and reporting. The shared marketplace is a module of the same product, not a separate business or disconnected app. Ecofarms is the platform operator and also a tenant; its private corporate Management Hub remains separate.

## Core workflows
1. Organization registers -> platform approval -> creates tenant workspace -> invites staff -> assigns permissions.
2. Farm/partner registration -> crop or livestock production plan -> activity records -> expected harvest -> quality check -> inventory.
3. Organization publishes approved available produce or upcoming harvest -> buyer discovers or posts demand -> seller accepts request -> order/reservation -> dispatch/collection -> delivery confirmation -> payment record -> audit trail.
4. AI retrieves authorized tenant records and curated agricultural references -> gives attributed advice and operational summaries -> escalates uncertain or high-risk issues to an agricultural expert; no invented listings, stock, prices or diagnoses.

## Roles and boundaries
Platform superadmin (Ecofarms SaaS operations), organization owner/admin, farm manager, field officer, sales/inventory staff, farmer/producer, buyer, verified expert. Implement explicit permission checks on the server and database; hide unauthorized UI only as an additional layer. Platform staff access to tenant business data must be restricted, logged and justified; platform superadmin is not automatically an unrestricted tenant operator.

## MVP modules
- Tenant onboarding, subscriptions/status and organization profile
- Secure authentication, invitations, roles and membership
- Farms, farmers and production cycles
- Harvest forecasts and available stock
- Marketplace: browse/search, available products, upcoming harvests, seller profiles, sourcing labels
- Buyer demand, quote/order requests, reservation requests, order status and fulfillment
- AI assistant with grounded retrieval, language preference, uncertainty and human escalation
- Organization dashboard, activity timeline, notifications and audit log
- Basic reporting and export

## Data model
organizations, organization_memberships, invitations, user_profiles, farms, farmers, production_cycles, harvest_forecasts, products, listings, listing_images, buyer_demands, quotes, orders, order_items, deliveries, payment_records, expert_cases, ai_interactions, notifications, audit_events, platform_approvals. Every private business row must carry organization_id; marketplace listings have explicit publication/visibility controls. Buyers who are external to a seller's organization access only their own orders and approved public listings.

## Database and security requirements
- Dedicated Farmers Connect Supabase project, NOT the existing Ecofarms Management Hub database.
- Enable and test RLS on every business table; enforce tenant membership using auth.uid() and organization_id. Do not trust organization_id supplied by a browser without server/database authorization.
- Separate public listing read policy from private seller records. Restrict contact details and exact farm locations by consent.
- Validate stock and reservation quantities atomically on the server; prevent overselling and duplicate order/payment processing.
- Audit approvals, listing changes, inventory changes, order transitions and AI-triggered actions.
- Use private storage and signed URLs for sensitive files; verify image upload type/size.
- No service-role key or AI provider secret in frontend code. Rate limit authentication, listings, messaging and AI requests.
- Explicit consent and deletion/retention policies for farmer and buyer data.

## Marketplace rules
- Listing states: draft, pending_review, published, paused, sold_out, rejected.
- Availability types: in_stock, upcoming_harvest; upcoming harvests are forecasts, not guaranteed inventory.
- Transaction states: inquiry, quoted, accepted, reserved, preparing, dispatched, delivered, completed, cancelled, disputed.
- Payment records describe confirmed external payments until a regulated payment integration is approved; never display a payment as settled solely on a buyer's claim.
- Seller badges Ecofarms Grown / Ecofarms Partner / Ecofarms Verified require platform-side verification and must not be self-selected.
- Ecofarms corporate site may display explicitly approved/syndicated listings through a narrow API, never direct unrestricted tenant access.

## AI rules
AI must respect tenant and user permissions; retrieve actual farm/marketplace records, show sources and timestamps for agronomic guidance, distinguish recommendations from verified facts, avoid fabricating demand or market prices, and route pesticide, animal health and other high-consequence questions to qualified local experts. Start English and Krio; expand languages with tested terminology and human review. Do not train external models on tenant data without explicit contractual permission.

## Build order and acceptance gates
1. Foundation: tenant schema, auth, RLS, roles, audit, organization onboarding. Gate: automated tests prove tenant A cannot read/write tenant B.
2. Farm operations: farm/farmer/production/harvest CRUD and forecasts. Gate: each action persists and appears only in authorized workspace.
3. Marketplace: listings, buyer demand, requests, reservations, order lifecycle. Gate: two organizations can trade without leaking private records; inventory consistency tested.
4. AI: permission-scoped retrieval, knowledge references, expert escalation, logging. Gate: fabricated listings and unauthorized data access rejected.
5. Integrations: Ecofarms corporate catalogue opt-in sync, notifications, payment provider only after verification. Gate: failure/retry, idempotency and audit tested.
6. Production: responsive and low-bandwidth UX, accessibility, security review, backups, monitoring, error tracking, staging sign-off and rollout.

## Repository/deployment note
The existing chatgpt.site URL is a prototype viewing URL. The Eco-farms-Limited repository is the public corporate site; Ecofarms-Management-Hub is private internal software. Neither has been confirmed to contain the Farmers Connect prototype source. Obtain/export the prototype source or create a dedicated Farmers Connect repository before claiming application modules are deployed. Do not merge tenant data into the private Hub.
