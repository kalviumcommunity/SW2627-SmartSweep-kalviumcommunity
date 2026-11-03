'use strict';
let token = sessionStorage.getItem('smartsweep-token') || '';
let state = null, pending = null, loading = false;
const $ = id => document.getElementById(id);
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const date = value => value == null ? '—' : new Date(value*1000).toLocaleString();
const message = value => { $('message').textContent = value; };
async function api(path, data) {
  const response = await fetch('/api/'+path, {method: data === undefined ? 'GET':'POST', headers:{'Content-Type':'application/json', ...(token ? {Authorization:'Bearer '+token}:{})}, ...(data === undefined ? {}:{body:JSON.stringify(data)}), signal:AbortSignal.timeout(10000)});
  const result = await response.json();
  if (!response.ok) { if (response.status===401 && path!=='login') signout(); throw new Error(result.error || 'Request failed'); }
  return result;
}
function signout(){token='';state=null;sessionStorage.removeItem('smartsweep-token');$('app').hidden=true;$('login').hidden=false;$('logout').hidden=true;$('identity').textContent='';}
function button(action,id,label){return `<button data-operation="${action}" data-id="${id}">${esc(label)}</button>`;}
function render(){
  $('login').hidden=true;$('app').hidden=false;$('logout').hidden=false;
  const supervisor=state.user.role==='supervisor';
  $('identity').textContent=`${state.user.email} · ${state.user.role}`;
  $('mode').textContent=state.demo ? 'DEMO MODE — Synthetic schedules and simulated clock. Records persist in the local database. No GPS hardware or physical collection is asserted.' : 'Local operations — Collection is operator-reported and independently reviewed. No GPS hardware integration.';
  $('updated').textContent='Operational time: '+date(state.now);
  $('advance').hidden=!state.demo||!supervisor;
  $('forms').hidden=!supervisor;
  $('metrics').innerHTML=Object.entries(state.metrics).map(([key,value])=>`<div class="metric"><strong>${value}</strong><span>${esc(key)}</span></div>`).join('');
  $('route-list').innerHTML=state.routes.map(r=>{
    let actions='';
    if(r.verified==null){
      if(r.started==null && state.now>=r.starts)actions+=button('start',r.id,'Start route');
      if(r.started!=null&&!r.interrupted&&r.claimed==null)actions+=button('collect',r.id,'Record collection');
      if(r.progress===r.stops&&r.claimed==null&&!r.interrupted)actions+=button('claim',r.id,'Claim completion');
      if(r.claimed!=null&&supervisor&&!r.interrupted)actions+=button('verify',r.id,'Review & verify');
      if(r.started!=null&&!r.interrupted)actions+=button('breakdown',r.id,'Report breakdown');
    }
    const records=state.collections.filter(c=>c.route_id===r.id);
    return `<article class="card" data-route="${r.id}"><h3>${esc(r.name)}</h3><span class="badge ${['missed','interrupted','delayed'].includes(r.status)?'bad':''}">${esc(r.status)}</span>${r.demo?'<span class="badge">Demo occurrence</span>':''}<p>${esc(r.zone)} · ${esc(r.vehicle)} · ${esc(r.driver)}</p><p class="meta">Start ${date(r.starts)} · Deadline ${date(r.deadline)}<br>Claimed ${date(r.claimed)} · Verified ${date(r.verified)}</p><progress value="${r.progress}" max="${r.stops}"></progress><p>${r.progress}/${r.stops} stops reported</p><details><summary>Collection evidence</summary><ul>${records.map(c=>`<li>Stop ${c.stop}: ${esc(c.evidence)} · ${date(c.recorded)} · Reporter #${c.actor}</li>`).join('')||'<li>No collection records</li>'}</ul></details><div class="toolbar">${actions}</div></article>`;
  }).join('')||'<p>No assigned collection routes.</p>';
  $('incident-list').innerHTML=state.incidents.map(i=>`<article class="card"><h3>${esc(i.kind)} · Route #${i.route_id}</h3><span class="badge ${i.resolved==null?'bad':''}">${i.resolved==null?'Unresolved':'Resolved'}</span><p>${esc(i.detail)}</p><p>${date(i.occurred)}</p>${i.resolved==null&&supervisor?button('resolve',i.id,'Record response'):''}${i.resolved!=null?`<p>Response: ${esc(i.resolution)} · ${date(i.resolved)}</p>`:''}</article>`).join('')||'<p>No alerts.</p>';
  $('rule').textContent=`Recurring = at least ${state.recurrence} missed occurrences in the selected ${state.days} days, grouped by zone and scheduled deadline. Recovery and alert resolution never erase a miss.`;
  $('analytics-list').innerHTML=state.analytics.map(a=>`<article class="card"><h3>${esc(a.zone)} ${a.recurring?'<span class="badge bad">Recurring failures</span>':''}</h3><p>${a.misses} missed / ${a.scheduled} due occurrences · Affected route IDs: ${a.route_ids.join(', ')||'none'}</p><p>Within this reporting period: recent 7 days ${a.recent_7_days}; preceding 7 days ${a.previous_7_days}</p></article>`).join('');
  $('event-list').innerHTML=state.events.map(e=>`<p class="card"><strong>${esc(e.kind)}</strong> · Route #${e.route_id} · ${date(e.occurred)}<br>${esc(e.detail)}<br><small>${esc(e.actor_email||'Automatic detector')}</small></p>`).join('');
  $('inventory').innerHTML=state.zones.map(z=>`<p>${esc(z.name)} · ${esc(z.schedule)} · ${z.active?'Active':'Inactive'} ${supervisor?button('zone-active',z.id,z.active?'Deactivate zone':'Activate zone'):''}</p>`).join('')+state.vehicles.map(v=>`<p>${esc(v.name)} · ${v.available?'Available':'Broken down'} ${!v.available&&supervisor?button('repair',v.id,'Record repair'):''}</p>`).join('')+state.drivers.map(d=>`<p>Team: ${esc(d.name)} · #${d.id}</p>`).join('');
  for(const [id,items] of [['zone-options',state.zones.filter(z=>z.active)],['vehicle-options',state.vehicles.filter(v=>v.available)],['driver-options',state.drivers]]){
    const select=$(id), value=select.value;
    select.innerHTML=items.map(item=>`<option value="${item.id}">${esc(item.name)}</option>`).join('');
    if(items.some(i=>String(i.id)===value))select.value=value;
  }
}
async function refresh(){if(!token||loading)return;loading=true;try{state=await api('state?days='+$('days').value);render();}catch(e){message('Refresh failed: '+e.message);}finally{loading=false;}}
$('login-form').onsubmit=async event=>{event.preventDefault();const b=event.submitter;b.disabled=true;try{const result=await api('login',Object.fromEntries(new FormData(event.target)));token=result.token;sessionStorage.setItem('smartsweep-token',token);event.target.reset();message('');await refresh();}catch(e){message(e.message);}finally{b.disabled=false;}};
$('logout').onclick=async()=>{try{await api('logout',{});signout();message('Signed out.');}catch(e){message(e.message);}};
$('refresh').onclick=refresh;$('days').onchange=refresh;
$('advance').onclick=async()=>{try{await api('advance',{seconds:7200});message('Demo clock advanced by two hours; detector evaluated persisted schedules.');await refresh();}catch(e){message(e.message);}};
document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{for(const id of ['routes','incidents','analytics','manage'])$(id).hidden=id!==b.dataset.tab;document.querySelectorAll('[data-tab]').forEach(n=>n.setAttribute('aria-current',String(n===b)));});
document.querySelector('[data-tab="routes"]').setAttribute('aria-current','true');
document.addEventListener('click',async event=>{
  const b=event.target.closest('[data-operation]');if(!b)return;
  const action=b.dataset.operation,id=Number(b.dataset.id);
  if(action==='zone-active'){try{await api(action,{id,active:state.zones.find(z=>z.id===id).active?0:1});await refresh();}catch(e){message(e.message);}return;}
  pending={action,id};$('action-title').textContent=b.textContent;
  $('action-description').textContent=action==='verify'?'Review the collection evidence first. Verification records a separate supervisor’s review, not sensor proof of physical collection.':action==='collect'?'Describe the collection reported at this stop. GPS proximity alone is not evidence of collection.':'This action will be saved in operational history.';
  const needs=['collect','verify','breakdown','resolve','repair'].includes(action);
  $('evidence-label').hidden=!needs;$('evidence').required=needs;$('evidence').value='';
  $('stop-label').hidden=action!=='collect';$('stop').required=action==='collect';
  if(action==='collect'){const r=state.routes.find(r=>r.id===id);$('stop').max=r.stops;const used=state.collections.filter(c=>c.route_id===id).map(c=>c.stop);$('stop').value=Array.from({length:r.stops},(_,i)=>i+1).find(i=>!used.includes(i))||1;}
  $('action-dialog').showModal();
});
$('cancel').onclick=()=>$('action-dialog').close();
$('action-form').onsubmit=async event=>{event.preventDefault();const b=event.submitter;b.disabled=true;try{const {action,id}=pending;await api(action,{id,route_id:id,stop:Number($('stop').value),evidence:$('evidence').value,resolution:$('evidence').value});$('action-dialog').close();message('Operational record saved.');await refresh();}catch(e){$('action-dialog').close();message(e.message);}finally{b.disabled=false;}};
document.querySelectorAll('[data-action]').forEach(form=>form.onsubmit=async event=>{event.preventDefault();const b=event.submitter;b.disabled=true;try{const data=Object.fromEntries(new FormData(form));for(const key of ['zone_id','vehicle_id','driver_id','stops'])if(key in data)data[key]=Number(data[key]);for(const key of ['starts','deadline'])if(key in data)data[key]=Math.floor(new Date(data[key]).getTime()/1000);await api(form.dataset.action,data);form.reset();message('Record created.');await refresh();}catch(e){message(e.message);}finally{b.disabled=false;}});
setInterval(refresh,5000);refresh();
