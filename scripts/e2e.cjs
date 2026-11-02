/* Real browser -> HTTP API -> temporary SQLite, isolated from user data. */
const {chromium} = require('playwright');
const {spawn} = require('node:child_process');
const {mkdtemp,rm,mkdir} = require('node:fs/promises');
const {tmpdir} = require('node:os');
const path = require('node:path');
const {randomBytes} = require('node:crypto');
const assert = require('node:assert/strict');

(async () => {
  const dir = await mkdtemp(path.join(tmpdir(),'smartsweep-e2e-'));
  const password = randomBytes(24).toString('hex');
  const port = Number(process.env.E2E_PORT || 8091);
  const base = `http://127.0.0.1:${port}`;
  const server = spawn(process.env.PYTHON || 'python3',['-u','-m','backend.server','--demo','--seed','--db',path.join(dir,'demo.db'),'--port',String(port)],{
    env:{...process.env,SMARTSWEEP_PASSWORD:password},stdio:['ignore','pipe','pipe']});
  let logs='';server.stderr.on('data',chunk=>logs+=chunk);
  let browser;
  try {
    let ready=false;
    for(let i=0;i<100;i++){
      if(server.exitCode!==null)throw Error('Server failed: '+logs);
      try{ready=(await fetch(base+'/api/health')).ok;}catch{}
      if(ready)break;
      await new Promise(resolve=>setTimeout(resolve,100));
    }
    assert(ready,'Local server did not start');
    browser=await chromium.launch({headless:true,...(process.env.CHROMIUM_PATH?{executablePath:process.env.CHROMIUM_PATH}:{}),args:['--no-sandbox']});
    const errors=[];
    const supervisor=await browser.newPage({viewport:{width:1280,height:900}});
    const driver=await browser.newPage({viewport:{width:390,height:844}});
    for(const page of [supervisor,driver])page.on('pageerror',e=>errors.push(e.message));
    async function login(page,email){await page.goto(base);await page.getByLabel('Email',{exact:true}).fill(email);await page.getByLabel('Password',{exact:true}).fill(password);await page.getByRole('button',{name:'Sign in',exact:true}).click();await page.locator('#app').waitFor({state:'visible'});}
    async function operate(page,routeId,label,evidence){
      await page.locator(`[data-route="${routeId}"]`).getByRole('button',{name:label,exact:true}).click();
      if(evidence)await page.locator('#evidence').fill(evidence);
      await page.getByRole('button',{name:'Save record',exact:true}).click();
      await page.locator('#action-dialog').waitFor({state:'hidden'});
      await page.getByRole('button',{name:'Refresh',exact:true}).click();
    }
    async function state(page){return await page.evaluate(async()=>{const r=await fetch('/api/state',{headers:{Authorization:'Bearer '+sessionStorage.getItem('smartsweep-token')}});return r.json();});}
    await login(supervisor,'supervisor@smartsweep.local');
    assert.equal((await state(supervisor)).metrics.missed,3);
    await supervisor.getByRole('button',{name:'Zones & fleet',exact:true}).click();
    const zone=supervisor.locator('form[data-action="zones"]');
    await zone.getByLabel('Name',{exact:true}).fill('Browser test zone');
    await zone.getByLabel('Schedule description').fill('Daily 08:00–10:00');
    await zone.getByRole('button',{name:'Create zone',exact:true}).click();
    await supervisor.locator('#inventory').getByText('Browser test zone',{exact:false}).waitFor();
    const vehicle=supervisor.locator('form[data-action="vehicles"]');
    await vehicle.getByLabel('Vehicle name').fill('Browser test vehicle');
    await vehicle.getByRole('button',{name:'Add vehicle',exact:true}).click();
    await supervisor.locator('#inventory').getByText('Browser test vehicle',{exact:false}).waitFor();
    const team=supervisor.locator('form[data-action="drivers"]');
    await team.getByLabel('Name',{exact:true}).fill('Browser test team');
    await team.getByLabel('Login email').fill('browser-driver@example.test');
    await team.getByLabel('Initial password').fill(password);
    await team.getByRole('button',{name:'Add driver',exact:true}).click();
    await supervisor.locator('#inventory').getByText('Browser test team',{exact:false}).waitFor();
    const routeForm=supervisor.locator('form[data-action="routes"]');
    await routeForm.getByLabel('Route name').fill('Browser verified route');
    await routeForm.getByLabel('Zone',{exact:true}).selectOption({label:'Browser test zone'});
    await routeForm.getByLabel('Vehicle',{exact:true}).selectOption({label:'Browser test vehicle'});
    await routeForm.getByLabel('Team',{exact:true}).selectOption({label:'Browser test team'});
    const localInput=seconds=>{const d=new Date(seconds*1000);return new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,16);};
    let current=await state(supervisor);
    await routeForm.getByLabel('Start',{exact:true}).fill(localInput(current.now));
    await routeForm.getByLabel('Deadline',{exact:true}).fill(localInput(current.now+3600));
    await routeForm.getByRole('button',{name:'Schedule route',exact:true}).click();
    await supervisor.getByRole('button',{name:'Routes',exact:true}).click();
    await supervisor.getByRole('heading',{name:'Browser verified route',exact:true}).waitFor();
    const rid=(await state(supervisor)).routes.find(r=>r.name==='Browser verified route').id;
    await login(driver,'browser-driver@example.test');
    assert.equal((await state(driver)).routes.length,1);
    await operate(driver,rid,'Start route');
    await operate(driver,rid,'Record collection','Demo operator report: stop one bins emptied.');
    await operate(driver,rid,'Record collection','Demo operator report: stop two bins emptied.');
    await operate(driver,rid,'Claim completion');
    assert.equal((await state(driver)).routes[0].status,'awaiting verification');
    await supervisor.getByRole('button',{name:'Refresh',exact:true}).click();
    await operate(supervisor,rid,'Review & verify','Demo supervisor reviewed both records and follow-up confirmation.');
    assert.equal((await state(supervisor)).routes.find(r=>r.id===rid).status,'completed');
    await driver.getByRole('button',{name:'Log out',exact:true}).click();
    await driver.locator('#login').waitFor({state:'visible'});
    await login(driver,'driver@smartsweep.local');
    await operate(driver,4,'Start route');
    await operate(driver,4,'Report breakdown','Demo engine failure during collection.');
    await supervisor.getByRole('button',{name:'Alerts',exact:true}).click();
    // No manual refresh: verify the 5-second poll delivers a driver incident.
    await supervisor.getByRole('heading',{name:'breakdown · Route #4',exact:true}).waitFor({timeout:12000});
    await supervisor.getByRole('button',{name:'Simulate +2 hours',exact:true}).click();
    await supervisor.getByRole('heading',{name:'missed · Route #4',exact:true}).waitFor();
    await supervisor.getByRole('button',{name:'Analytics & history',exact:true}).click();
    await supervisor.getByText('4 missed / 4 due occurrences',{exact:false}).waitFor();
    await supervisor.reload();
    await supervisor.locator('#app').waitFor({state:'visible'});
    current=await state(supervisor);
    assert.equal(current.routes.find(r=>r.id===rid).status,'completed');
    assert.equal(current.incidents.filter(i=>i.route_id===4&&i.kind==='breakdown').length,1);
    assert.equal(current.analytics.find(z=>z.zone_id===1).misses,4);
    await mkdir('test-results',{recursive:true});
    await supervisor.screenshot({path:'test-results/supervisor.png',fullPage:true});
    await driver.screenshot({path:'test-results/driver-mobile.png',fullPage:true});
    assert.equal(await driver.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true,'Mobile overflow');
    assert.deepEqual(errors,[]);
    console.log('PASS: browser login, zone/vehicle/driver creation, scheduling, driver progress, independent verification, breakdown polling, missed deadline, recurrence, reload, mobile layout; no browser exceptions.');
  } finally {
    if(browser)await browser.close();
    server.kill('SIGTERM');
    await new Promise(resolve=>server.exitCode!==null?resolve():server.once('exit',resolve));
    await rm(dir,{recursive:true,force:true});
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
