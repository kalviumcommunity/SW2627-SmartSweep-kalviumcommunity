/* DOM integration (not a rendering/browser test) against the real HTTP service. */
const {JSDOM,VirtualConsole}=require('jsdom');
const {spawn}=require('node:child_process');
const fs=require('node:fs/promises');
const path=require('node:path');
const os=require('node:os');
const assert=require('node:assert/strict');
const {randomBytes}=require('node:crypto');
(async()=>{
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'smartsweep-dom-'));
 const password=randomBytes(24).toString('hex');
 const base='http://127.0.0.1:8092';
 const server=spawn(process.env.PYTHON||'python3',['-u','-m','backend.server','--demo','--seed','--db',path.join(dir,'test.db'),'--port','8092'],{env:{...process.env,SMARTSWEEP_PASSWORD:password},stdio:['ignore','pipe','pipe']});
 let logs='';server.stderr.on('data',b=>logs+=b);
 const windows=[];const errors=[];
 const wait=async(fn,label)=>{for(let i=0;i<150;i++){if(fn())return;await new Promise(r=>setTimeout(r,50));}throw Error('Timed out: '+label);};
 try{
  let ready=false;for(let i=0;i<100;i++){try{ready=(await fetch(base+'/api/health')).ok;}catch{}if(ready)break;await new Promise(r=>setTimeout(r,100));}
  assert(ready,logs);
  const newClient=async()=>{
   const vc=new VirtualConsole();vc.on('jsdomError',e=>errors.push(e.message));
   const dom=await JSDOM.fromURL(base,{resources:'usable',runScripts:'dangerously',virtualConsole:vc,beforeParse(w){
    w.fetch=(url,options)=>fetch(new URL(url,base),options);w.AbortSignal=AbortSignal;
    w.HTMLDialogElement.prototype.showModal=function(){this.open=true;};
    w.HTMLDialogElement.prototype.close=function(){this.open=false;};
   }});windows.push(dom.window);await new Promise(r=>dom.window.addEventListener('load',r));return dom.window;
  };
  const submit=(w,form)=>form.dispatchEvent(new w.SubmitEvent('submit',{bubbles:true,cancelable:true,submitter:form.querySelector('button:not([type="button"])')}));
  const login=async(w,email)=>{const f=w.document.querySelector('#login-form');f.elements.email.value=email;f.elements.password.value=password;submit(w,f);await wait(()=>!w.document.getElementById('app').hidden,'login');};
  const getState=async w=>(await fetch(base+'/api/state',{headers:{Authorization:'Bearer '+w.sessionStorage.getItem('smartsweep-token')}})).json();
  const refresh=async w=>{w.document.getElementById('refresh').click();await new Promise(r=>setTimeout(r,150));};
  const operate=async(w,id,action,evidence='Test evidence')=>{
   const button=w.document.querySelector(`[data-route="${id}"] [data-operation="${action}"]`);assert(button,`Missing ${action} button`);button.click();
   w.document.getElementById('evidence').value=evidence;
   submit(w,w.document.getElementById('action-form'));
   await wait(()=>!w.document.getElementById('action-dialog').open,action);
   await refresh(w);
  };
  const supervisor=await newClient();await login(supervisor,'supervisor@smartsweep.local');
  const d=supervisor.document;
  assert(d.getElementById('route-list').textContent.includes('Morning collection'));
  assert(d.getElementById('analytics-list').textContent.includes('Recurring failures'));
  async function create(action,values){const f=d.querySelector(`[data-action="${action}"]`);for(const[k,v]of Object.entries(values))f.elements[k].value=v;submit(supervisor,f);await wait(()=>!f.querySelector('button').disabled,action);await refresh(supervisor);assert(!d.getElementById('message').textContent.includes('error'),d.getElementById('message').textContent);}
  await create('zones',{name:'DOM zone <script>unsafe</script>',schedule:'Daily'});
  await create('vehicles',{name:'DOM truck'});
  await create('drivers',{name:'DOM team',email:'dom-driver@example.test',password});
  let s=await getState(supervisor);
  const zone=s.zones.find(z=>z.name.startsWith('DOM zone')),vehicle=s.vehicles.find(v=>v.name==='DOM truck'),team=s.drivers.find(t=>t.name==='DOM team');
  assert(zone&&vehicle&&team,'Management forms must persist records');
  assert(!d.getElementById('inventory').querySelector('script'),'User input must be escaped');
  const localInput=seconds=>{const dt=new Date(seconds*1000);return new Date(dt.getTime()-dt.getTimezoneOffset()*60000).toISOString().slice(0,16);};
  await create('routes',{name:'DOM verified route',zone_id:zone.id,vehicle_id:vehicle.id,driver_id:team.id,starts:localInput(s.now),deadline:localInput(s.now+3600),stops:2});
  s=await getState(supervisor);const rid=s.routes.find(r=>r.name==='DOM verified route').id;
  const driver=await newClient();await login(driver,'dom-driver@example.test');
  assert.equal((await getState(driver)).routes.length,1);
  await operate(driver,rid,'start');
  await operate(driver,rid,'collect','Reported first stop');
  await operate(driver,rid,'collect','Reported second stop');
  await operate(driver,rid,'claim');
  assert.equal((await getState(driver)).routes[0].status,'awaiting verification');
  await refresh(supervisor);await operate(supervisor,rid,'verify','Independent supervisor reviewed records');
  assert.equal((await getState(supervisor)).routes.find(r=>r.id===rid).status,'completed');
  await operate(supervisor,4,'start');await operate(supervisor,4,'breakdown','Engine failure');
  assert(d.getElementById('incident-list').textContent.includes('breakdown'));
  d.getElementById('advance').click();
  await wait(()=>d.getElementById('analytics-list').textContent.includes('4 missed / 4 due'),'recurrence update');
  s=await getState(supervisor);assert.equal(s.incidents.filter(i=>i.route_id===4&&i.kind==='missed').length,1);
  assert.equal(s.routes.find(r=>r.id===rid).status,'completed');
  d.getElementById('logout').click();await wait(()=>!d.getElementById('login').hidden,'logout');
  assert.deepEqual(errors,[]);
  console.log('PASS: real HTTP + DOM integration: login, zone/vehicle/team forms, escaped input, scheduling, driver progress, independent verification, breakdown alert, missed detection, recurrence, logout. No DOM script errors. Rendering not tested.');
 }finally{
  for(const w of windows)w.close();server.kill();await new Promise(r=>server.exitCode!==null?r():server.once('exit',r));await fs.rm(dir,{recursive:true,force:true});
 }
})().catch(e=>{console.error(e);process.exitCode=1;});
