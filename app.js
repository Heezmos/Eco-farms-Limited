const menuButton=document.querySelector("[data-menu-button]"),nav=document.querySelector("[data-nav]");if(menuButton&&nav){menuButton.addEventListener("click",()=>{const open=nav.classList.toggle("open");menuButton.setAttribute("aria-expanded",String(open))});nav.querySelectorAll("a").forEach(a=>a.addEventListener("click",()=>{nav.classList.remove("open");menuButton.setAttribute("aria-expanded","false")}))}const reveal=()=>document.querySelectorAll(".reveal").forEach(el=>el.classList.add("visible"));if("IntersectionObserver"in window){const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){entry.target.classList.add("visible");observer.unobserve(entry.target)}}),{threshold:.12});document.querySelectorAll(".reveal").forEach(el=>observer.observe(el))}else reveal();

const FC_API_URL="https://ialobcshxbesmncngixx.supabase.co";
const FC_PUBLIC_KEY="sb_publishable_5fmGpjGAQm7qwUS1xtp-zg_CI4fenzN";
async function fcRpc(name,body={}){
 const r=await fetch(FC_API_URL+"/rest/v1/rpc/"+name,{method:"POST",headers:{"Content-Type":"application/json","apikey":FC_PUBLIC_KEY},body:JSON.stringify(body)});
 if(!r.ok)throw new Error("Marketplace request failed");
 return r.status===204?null:r.json();
}
async function loadPublicMarketplace(){
 const grid=document.querySelector("#public-market-grid");if(!grid)return;
 try{
  const rows=await fcRpc("fc_public_marketplace");
  if(!rows?.length){grid.innerHTML='<div class="market-empty"><strong>No products published yet.</strong><p>Approved Farmers Connect listings will automatically appear here.</p></div>';return}
  grid.innerHTML=rows.map(r=>'<article class="market-card"><div class="market-card-top"><span class="market-badge">'+(r.verification_badge||"Verified supply")+'</span><span>'+(r.availability_type==="upcoming_harvest"?"Upcoming harvest":"Available now")+'</span></div><h3>'+r.product_name+'</h3><p>'+(r.variety||"Agricultural produce")+'</p><strong>'+r.available_quantity+' '+r.quantity_unit+(r.unit_price!=null?' · '+r.currency+' '+r.unit_price:'')+'</strong><small>'+r.seller_name+(r.location?' · '+r.location:'')+'</small><button type="button" class="button gold" data-market-view="'+r.id+'">View product</button></article>').join("");
  grid.querySelectorAll("[data-market-view]").forEach(b=>b.addEventListener("click",async()=>{try{await fcRpc("fc_track_listing_view",{p_listing_id:b.dataset.marketView});b.textContent="Viewed · Request ordering coming next";b.disabled=true}catch{}}));
 }catch{grid.innerHTML='<div class="market-empty"><strong>Marketplace temporarily unavailable.</strong><p>Please try again shortly.</p></div>'}
}
loadPublicMarketplace();
