import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';

/// Operational screens backed exclusively by persisted API records.
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key, this.api});
  final OperationsApi? api;
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  late final OperationsApi api = widget.api ?? OperationsApi();
  final email = TextEditingController();
  final password = TextEditingController();
  Map<String, dynamic>? data;
  Timer? timer;
  String? error;
  bool busy = false;
  bool refreshing = false;
  int tab = 0;
  int days = 30;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    email.dispose();
    password.dispose();
    if (widget.api == null) api.close();
    super.dispose();
  }

  Future<void> refresh() async {
    if (api.token == null || refreshing) return;
    refreshing = true;
    try {
      final result = await api.request('state?days=$days');
      if (mounted) setState(() { data = result; error = null; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); if (api.token == null) data = null; });
    } finally {
      refreshing = false;
    }
  }

  Future<void> run(Future<void> Function() operation) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      await operation();
      await refresh();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<Map<String, dynamic>> rows(String key) =>
      (data?[key] as List? ?? []).cast<Map<String, dynamic>>();
  bool get supervisor => data?['user']['role'] == 'supervisor';
  String date(dynamic value) => value == null ? '—' :
      DateTime.fromMillisecondsSinceEpoch((value as num).round() * 1000)
          .toLocal().toString().split('.').first;

  Future<void> action(String name, int id) async {
    final fields = <String, String>{
      if (name == 'collect') 'stop': 'Stop number',
      if (['collect','verify','breakdown','repair'].contains(name))
        'evidence': 'Evidence / incident details / review notes',
      if (name == 'resolve') 'resolution': 'Response and follow-up',
    };
    final result = await input(name, fields);
    if (result == null) return;
    if (result.containsKey('stop')) result['stop'] = int.tryParse(result['stop']);
    await run(() async { await api.request(name, {'id': id, 'route_id': id, ...result}); });
  }

  Future<Map<String, dynamic>?> input(String title, Map<String,String> fields,
      {Map<String,List<Map<String,dynamic>>> choices = const {}}) async {
    final controllers = {for (final key in fields.keys) key: TextEditingController()};
    final selections = <String,int?>{for (final key in choices.keys)
      key: choices[key]!.isEmpty ? null : choices[key]!.first['id'] as int};
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String,dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: 440, child: Form(key: form, child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (title == 'verify') const Text('Review collection records first. A different supervisor must verify. This records human review, not sensor proof.'),
            for (final field in fields.entries) Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextFormField(controller: controllers[field.key],
                obscureText: field.key == 'password',
                decoration: InputDecoration(labelText: field.value),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
            ),
            for (final choice in choices.entries) DropdownButtonFormField<int>(
              initialValue: selections[choice.key],
              decoration: InputDecoration(labelText: choice.key),
              items: choice.value.map((v) => DropdownMenuItem<int>(value: v['id'] as int, child: Text(v['name'] as String))).toList(),
              onChanged: (v) => selections[choice.key] = v,
              validator: (v) => v == null ? 'Create an available record first' : null,
            ),
          ]),
        ))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(context,
                <String,dynamic>{for (final e in controllers.entries) e.key: e.value.text.trim(), ...selections});
            }
          }, child: const Text('Save record'))],
      ),
    );
    // Wait for the dialog route's closing transition before disposing controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final c in controllers.values) { c.dispose(); }
    return result;
  }

  Widget command(String label, String actionName, int id) => OutlinedButton(
    onPressed: busy ? null : () => action(actionName,id), child: Text(label));

  Widget route(Map<String,dynamic> r) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${r['name']} · ${r['status']}', style: Theme.of(context).textTheme.titleMedium),
      Text('${r['zone']} · ${r['vehicle']} · ${r['driver']}'),
      Text('Start ${date(r['starts'])}\nDeadline ${date(r['deadline'])}'),
      if (r['demo'] == 1) const Text('DEMO occurrence'),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: (r['progress'] as num)/(r['stops'] as num)),
      Text('${r['progress']}/${r['stops']} stops reported · Verified ${date(r['verified'])}'),
      for (final c in rows('collections').where((c) => c['route_id']==r['id']))
        Text('Stop ${c['stop']}: ${c['evidence']} · reporter #${c['actor']}'),
      if (r['verified'] == null) Wrap(spacing: 8, children: [
        if (r['started'] == null && (data!['now'] as num) >= (r['starts'] as num)) command('Start route','start',r['id']),
        if (r['started'] != null && r['interrupted'] == 0 && r['claimed'] == null) command('Record collection','collect',r['id']),
        if (r['progress'] == r['stops'] && r['claimed'] == null && r['interrupted'] == 0) command('Claim completion','claim',r['id']),
        if (supervisor && r['claimed'] != null && r['interrupted'] == 0) command('Review & verify','verify',r['id']),
        if (r['started'] != null && r['interrupted'] == 0) command('Report breakdown','breakdown',r['id']),
      ]),
    ]),
  ));

  Future<void> create(String kind, Map<String,String> fields) async {
    final result = await input('Create $kind',fields,choices: kind == 'routes' ? {
      'zone_id': rows('zones').where((z) => z['active']==1).toList(),
      'vehicle_id': rows('vehicles').where((v) => v['available']==1).toList(),
      'driver_id': rows('drivers'),
    } : const {});
    if (result == null) return;
    await run(() async {
      if (kind == 'routes') {
        result['stops'] = int.tryParse(result['stops']);
        for (final key in ['starts','deadline']) {
          final parsed = DateTime.tryParse(result[key]);
          if (parsed == null) throw const FormatException('Use date/time YYYY-MM-DD HH:MM');
          result[key] = parsed.millisecondsSinceEpoch ~/ 1000;
        }
      }
      await api.request(kind,result);
    });
  }

  List<Widget> content() {
    if (tab == 0) {
      return [
        const Text('Collection records are operator reports; verified completion requires a different supervisor’s review.'),
        for (final r in rows('routes')) route(r),
      ];
    }
    if (tab == 1) {
      return [
        const Text('Alert resolution does not erase failures or verify collection.'),
        for (final i in rows('incidents')) Card(child: ListTile(
          title: Text('${i['kind']} · Route #${i['route_id']} · ${i['resolved'] == null ? 'Unresolved' : 'Resolved'}'),
          subtitle: Text('${i['detail']}\n${date(i['occurred'])}\n${i['resolution'] ?? ''}'),
          trailing: supervisor && i['resolved'] == null ? command('Respond','resolve',i['id']) : null,
        )),
      ];
    }
    if (tab == 2) {
      return [
        Text('Recurring = ${data!['recurrence']} or more missed occurrences per zone in $days days. Misses remain after recovery.'),
        DropdownButton<int>(value: days, items: [7,30,90,365].map((v) => DropdownMenuItem(value:v,child:Text('$v days'))).toList(),
          onChanged: (v) { setState(() => days=v!); refresh(); }),
        for (final a in rows('analytics')) Card(child: ListTile(
          title: Text('${a['zone']} · ${a['recurring'] == true ? 'Recurring failures' : 'Below recurrence threshold'}'),
          subtitle: Text('${a['misses']} missed / ${a['scheduled']} due\nAffected routes: ${a['route_ids']}\nRecent 7 days: ${a['recent_7_days']}; preceding 7: ${a['previous_7_days']}'),
        )),
        const Text('Event history'),
        for (final e in rows('events')) ListTile(title: Text('${e['kind']} · Route #${e['route_id']}'),
          subtitle: Text('${date(e['occurred'])} · ${e['actor_email'] ?? 'Automatic detector'}\n${e['detail']}')),
      ];
    }
    return [
      for (final z in rows('zones')) ListTile(title: Text(z['name']),subtitle: Text('${z['schedule']} · ${z['active']==1?'Active':'Inactive'}'),
        trailing: supervisor ? TextButton(onPressed: busy ? null : () => run(() async { await api.request('zone-active',{'id':z['id'],'active':z['active']==1?0:1}); }),child:const Text('Toggle active')) : null),
      for (final v in rows('vehicles')) ListTile(title: Text(v['name']),subtitle: Text(v['available']==1?'Available':'Broken down'),
        trailing: supervisor && v['available']==0 ? command('Record repair','repair',v['id']) : null),
      for (final d in rows('drivers')) ListTile(title: Text(d['name']),subtitle: Text('Team #${d['id']}')),
      if (supervisor) Wrap(spacing:8,children:[
        OutlinedButton(onPressed:busy?null:()=>create('zones',{'name':'Zone name','schedule':'Schedule description'}),child:const Text('Create zone')),
        OutlinedButton(onPressed:busy?null:()=>create('vehicles',{'name':'Vehicle name'}),child:const Text('Add vehicle')),
        OutlinedButton(onPressed:busy?null:()=>create('drivers',{'name':'Team name','email':'Email','password':'Password (12+ characters)'}),child:const Text('Add driver')),
        OutlinedButton(onPressed:busy?null:()=>create('routes',{'name':'Route name','starts':'Start: YYYY-MM-DD HH:MM','deadline':'Deadline: YYYY-MM-DD HH:MM','stops':'Number of stops (1–100)'}),child:const Text('Schedule route')),
      ]),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SmartSweep operations'),actions: [
      if (data != null) IconButton(tooltip:'Refresh',onPressed:refresh,icon:const Icon(Icons.refresh)),
      if (data != null) IconButton(tooltip:'Log out',onPressed:busy?null:()=>run(() async {
        await api.request('logout',{});api.token=null;
        if (mounted) setState(() => data=null);
      }),icon:const Icon(Icons.logout)),
    ]),
    body: data == null ? Center(child: SizedBox(width:420,child:ListView(shrinkWrap:true,padding:const EdgeInsets.all(24),children:[
      Text('Sign in to local operations',style:Theme.of(context).textTheme.headlineSmall),
      const Text('Use the account created by the local server setup.'),
      TextField(controller:email,decoration:const InputDecoration(labelText:'Email'),keyboardType:TextInputType.emailAddress),
      TextField(controller:password,decoration:const InputDecoration(labelText:'Password'),obscureText:true),
      if(error!=null) Text(error!,style:const TextStyle(color:Colors.red)),
      const SizedBox(height:16),
      FilledButton(onPressed:busy?null:()=>run(() async {await api.login(email.text,password.text);password.clear();}),child:Text(busy?'Signing in…':'Sign in')),
    ]))) : ListView(padding:const EdgeInsets.all(16),children:[
      Text('${data!['user']['email']} · ${data!['user']['role']}'),
      if(data!['demo']==true) const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('DEMO MODE — Synthetic schedules and simulated clock. Persisted records; no GPS hardware or physical collection asserted.'))),
      Text('Operational time: ${date(data!['now'])} · Polling every 5 seconds'),
      if(error!=null) Text(error!,style:const TextStyle(color:Colors.red)),
      if(busy) const LinearProgressIndicator(),
      Wrap(spacing:8,children:[for(final e in (data!['metrics'] as Map<String,dynamic>).entries) Chip(label:Text('${e.key}: ${e.value}'))]),
      if(supervisor&&data!['demo']==true) Align(alignment:Alignment.centerLeft,child:OutlinedButton(onPressed:busy?null:()=>run(() async {await api.request('advance',{'seconds':7200});}),child:const Text('Simulate +2 hours'))),
      ...content(),
    ]),
    bottomNavigationBar: data==null?null:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const [
      NavigationDestination(icon:Icon(Icons.route),label:'Routes'),
      NavigationDestination(icon:Icon(Icons.notifications),label:'Alerts'),
      NavigationDestination(icon:Icon(Icons.analytics),label:'Analytics'),
      NavigationDestination(icon:Icon(Icons.local_shipping),label:'Zones & fleet'),
    ]),
  );
}
