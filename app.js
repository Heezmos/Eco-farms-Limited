const SUPABASE_URL = "https://qeabpfnmifrgqoyqazcz.supabase.co";
const SUPABASE_KEY = "sb_publishable_i0ZKnFQFcVEKxb6E2VyIqA_jSI1-n-8";

const headers = { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}`, "Content-Type": "application/json" };
const analyticsSession = (() => {
  try {
    const existing = sessionStorage.getItem("ecofarms_analytics_session");
    if (existing) return existing;
    const created = crypto.randomUUID();
    sessionStorage.setItem("ecofarms_analytics_session", created);
    return created;
  } catch {
    return crypto.randomUUID();
  }
})();
const referrerHost = (() => {
  try { return document.referrer ? new URL(document.referrer).hostname : null; }
  catch { return null; }
})();
function track(event_name, details = {}) {
  const payload = {
    session_id: analyticsSession,
    event_name,
    page_path: location.pathname.slice(0, 300) || "/",
    section: details.section?.slice(0, 80) || null,
    target: details.target?.slice(0, 160) || null,
    referrer_host: referrerHost,
  };
  void fetch(`${SUPABASE_URL}/rest/v1/eco_website_events`, {
    method: "POST",
    headers: { ...headers, Prefer: "return=minimal" },
    body: JSON.stringify(payload),
    keepalive: true,
  }).catch(() => {});
}

document.querySelector("[data-year]").textContent = new Date().getFullYear();
const menuButton = document.querySelector("[data-menu-button]");
const nav = document.querySelector("[data-nav]");
menuButton.addEventListener("click", () => { const open = nav.classList.toggle("open"); menuButton.setAttribute("aria-expanded", String(open)); });
nav.querySelectorAll("a").forEach((link) => link.addEventListener("click", () => { nav.classList.remove("open"); menuButton.setAttribute("aria-expanded", "false"); }));

const observer = new IntersectionObserver((entries) => entries.forEach((entry) => entry.isIntersecting && entry.target.classList.add("visible")), { threshold: 0.08 });
document.querySelectorAll(".reveal").forEach((element) => observer.observe(element));

const label = (value) => ({ ecofarms_grown: "Ecofarms Grown", ecofarms_partner: "Ecofarms Partner", ecofarms_verified: "Ecofarms Verified" })[value] || value;

async function loadProducts() {
  const container = document.querySelector("[data-products]");
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/eco_products?select=name,category,sourcing_identity,unit,description&is_active=eq.true&order=name.asc`, { headers });
    if (!response.ok) throw new Error("Catalogue unavailable");
    const products = await response.json();
    container.innerHTML = products.map((product) => `<article class="product-card" data-product="${escapeHtml(product.name)}"><span class="category">${escapeHtml(product.category.replaceAll("_", " "))}</span><h3>${escapeHtml(product.name)}</h3><p>${escapeHtml(product.description || "Available according to production and supply planning.")}</p><small>${escapeHtml(label(product.sourcing_identity))} · per ${escapeHtml(product.unit)}</small></article>`).join("");
  } catch {
    container.innerHTML = '<p class="loading">Our catalogue is temporarily unavailable. Please use the supply request form or contact Ecofarms directly.</p>';
  }
}

function escapeHtml(value) { const node = document.createElement("div"); node.textContent = String(value); return node.innerHTML; }
function clean(value) { const text = value.trim(); return text || null; }
function numberOrNull(value) { return value === "" ? null : Number(value); }
function showMessage(form, type, text) { const box = form.querySelector(".form-message"); box.className = `form-message ${type}`; box.textContent = text; }

async function submitRecord(table, payload) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, { method: "POST", headers: { ...headers, Prefer: "return=minimal" }, body: JSON.stringify(payload) });
  if (!response.ok) throw new Error("Submission failed");
}

function reference(prefix) { return `${prefix}-${crypto.randomUUID().replaceAll("-", "").slice(0, 10).toUpperCase()}`; }

document.querySelector('[data-form="farmer"]').addEventListener("submit", async (event) => {
  event.preventDefault(); const form = event.currentTarget;
  const products = [...form.querySelectorAll('input[name="primary_products"]:checked')].map((item) => item.value);
  if (!form.reportValidity() || products.length === 0) { showMessage(form, "error", "Please complete the required fields and select at least one product."); return; }
  const data = new FormData(form); const button = form.querySelector("button[type=submit]"); button.disabled = true; button.textContent = "Submitting…";
  try {
    const ref = reference("EFA");
    await submitRecord("eco_farmer_applications", { reference_number: ref, full_name: clean(data.get("full_name")), phone: clean(data.get("phone")), email: clean(data.get("email")), district: clean(data.get("district")), chiefdom: clean(data.get("chiefdom")), community: clean(data.get("community")), farm_size_hectares: numberOrNull(data.get("farm_size_hectares")), experience_years: numberOrNull(data.get("experience_years")), primary_products: products, notes: clean(data.get("notes")) });
    form.reset(); showMessage(form, "success", `Application received successfully. Keep your reference: ${ref}`); track("farmer_form_submit", { section: "partners" });
  } catch { showMessage(form, "error", "We could not submit your application right now. Please check your connection and try again."); }
  finally { button.disabled = false; button.textContent = "Submit farmer application"; }
});

document.querySelector('[data-form="supply"]').addEventListener("submit", async (event) => {
  event.preventDefault(); const form = event.currentTarget;
  if (!form.reportValidity()) return;
  const data = new FormData(form); const button = form.querySelector("button[type=submit]"); button.disabled = true; button.textContent = "Submitting…";
  try {
    const ref = reference("ESR");
    await submitRecord("eco_supply_requests", { reference_number: ref, organization_name: clean(data.get("organization_name")), contact_name: clean(data.get("contact_name")), phone: clean(data.get("phone")), email: clean(data.get("email")), buyer_segment: clean(data.get("buyer_segment")), delivery_location: clean(data.get("delivery_location")), requested_items: [{ description: clean(data.get("items")) }], frequency: clean(data.get("frequency")), required_from: clean(data.get("required_from")), notes: clean(data.get("notes")) });
    form.reset(); showMessage(form, "success", `Supply request received. Keep your reference: ${ref}`); track("supply_form_submit", { section: "supply" });
  } catch { showMessage(form, "error", "We could not submit your request right now. Please check your connection and try again."); }
  finally { button.disabled = false; button.textContent = "Send supply request"; }
});

track("page_view", { section: "home" });
const viewedSections = new Set();
const analyticsObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting && entry.target.id && !viewedSections.has(entry.target.id)) {
      viewedSections.add(entry.target.id);
      track("section_view", { section: entry.target.id });
      analyticsObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.35 });
document.querySelectorAll("main section[id]").forEach((section) => analyticsObserver.observe(section));
document.querySelectorAll("header a, footer a").forEach((link) => link.addEventListener("click", () =>
  track("navigation_click", { section: "navigation", target: link.textContent.trim() })
));
const farmerForm = document.querySelector('[data-form="farmer"]');
const supplyForm = document.querySelector('[data-form="supply"]');
farmerForm.addEventListener("focusin", () => track("farmer_form_start", { section: "partners" }), { once: true });
supplyForm.addEventListener("focusin", () => track("supply_form_start", { section: "supply" }), { once: true });

loadProducts();
