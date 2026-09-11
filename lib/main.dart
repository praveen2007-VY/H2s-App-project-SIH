import 'dart:math' as math;
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.supabaseConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabasePublishableKey);
  }
  runApp(const H2SSafetyApp());
}

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  String role = 'Worker';
  String userName = 'Demo Worker';
  double exposure = 18;
  String risk = 'Safe';
  XFile? lastImage;
  Position? lastPosition;
  final scans = <Map<String, dynamic>>[
    {'time': '10:42 AM', 'exposure': 18, 'risk': 'Safe', 'site': 'Site A'},
    {'time': '09:10 AM', 'exposure': 27, 'risk': 'Safe', 'site': 'Site A'},
    {'time': 'Yesterday 4:30 PM', 'exposure': 62, 'risk': 'Warning', 'site': 'Tank Area'},
  ];
  final alerts = <Map<String, dynamic>>[
    {'level': 'Critical', 'title': 'H₂S exposure detected', 'worker': 'Employee 104', 'location': 'Processing Area 3', 'exposure': 91},
    {'level': 'Warning', 'title': 'Elevated exposure', 'worker': 'Employee 087', 'location': 'Tank Area', 'exposure': 62},
  ];

  void toggleTheme() { themeMode = themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light; notifyListeners(); }
  void setRole(String r) { role = r; notifyListeners(); }
  void setUser(String n) { userName = n; notifyListeners(); }
  void setScan({required double value, required XFile image, Position? position}) {
    exposure = value; risk = value >= 75 ? 'Critical' : value >= 45 ? 'Warning' : 'Safe'; lastImage = image; lastPosition = position;
    scans.insert(0, {'time': 'Now', 'exposure': value.round(), 'risk': risk, 'site': 'Current Site'});
    if (risk == 'Critical') alerts.insert(0, {'level': 'Critical', 'title': 'Critical scan result', 'worker': userName, 'location': 'Current Site', 'exposure': value.round()});
    notifyListeners();
  }
}

class H2SSafetyApp extends StatefulWidget { const H2SSafetyApp({super.key}); @override State<H2SSafetyApp> createState() => _H2SSafetyAppState(); }
class _H2SSafetyAppState extends State<H2SSafetyApp> {
  final appState = AppState();
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (_, __) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'H₂S Safety Platform',
      themeMode: appState.themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      initialRoute: '/welcome',
      onGenerateRoute: (s) => MaterialPageRoute(builder: (_) => routeWidget(s.name ?? '/welcome', appState), settings: s),
    ),
  );
}

ThemeData buildTheme(Brightness b) => ThemeData(
  brightness: b,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF12213B), brightness: b),
  scaffoldBackgroundColor: b == Brightness.dark ? const Color(0xFF0C111B) : const Color(0xFFF5F7FA),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), filled: true),
  cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
);

Widget routeWidget(String name, AppState state) {
  final builder = routeBuilders[name];
  return builder != null ? builder(state) : GenericScreen(title: screenTitles[name] ?? pretty(name), state: state);
}

String pretty(String path) => path.replaceFirst('/', '').replaceAll('-', ' ').replaceAll('_', ' ');

final Map<String, String> screenTitles = {
  ...{
    '/splash': 'Splash', '/login': 'Login', '/register': 'Worker Registration', '/otp': 'OTP Verification', '/forgot-password': 'Forgot Password', '/reset-password': 'Password Reset', '/activation': 'Account Activation',
    '/dashboard': 'Worker Dashboard', '/scan-instructions': 'Scan Instructions', '/scan-method': 'Scan Method', '/camera': 'Camera Preview', '/image-review': 'Image Review', '/strip-detection': 'Strip Detection', '/color-extraction': 'Color Extraction', '/analysis': 'Analysis Processing', '/result': 'Scan Result', '/exposure-details': 'Exposure Details', '/image-details': 'Scan Image Details', '/scan-notes': 'Scan Notes', '/scan-confirmation': 'Scan Confirmation',
    '/history': 'Scan History', '/scan-details': 'Historical Scan Details', '/analytics': 'Worker Analytics', '/exposure-trend': 'Exposure Trend', '/risk-distribution': 'Risk Distribution', '/alert-center': 'Alert Center', '/alert-details': 'Alert Details', '/notifications': 'Notifications', '/notification-settings': 'Notification Settings', '/location-permission': 'Location Permission', '/current-location': 'Current Location', '/location-history': 'Location History', '/site-zone': 'Site / Zone Information', '/profile': 'Profile', '/edit-profile': 'Edit Profile', '/security': 'Security', '/settings': 'App Settings', '/help': 'Help & Support', '/reports': 'Reports', '/report-preview': 'Report Preview', '/export': 'Export',
  },
  ...{
    '/admin-login': 'Admin Login', '/admin-mfa': 'MFA Verification', '/admin-password-recovery': 'Admin Password Recovery', '/admin-security': 'Session & Security', '/admin-dashboard': 'Operations Dashboard', '/workers': 'Worker List', '/worker-details': 'Worker Details', '/add-worker': 'Add Worker', '/edit-worker': 'Edit Worker', '/worker-permissions': 'Worker Permissions', '/worker-activity': 'Worker Activity', '/exposure-overview': 'Exposure Overview', '/exposure-trends': 'Exposure Trends', '/risk-analytics': 'Risk Analytics', '/worker-comparison': 'Worker Comparison', '/site-comparison': 'Site Comparison', '/historical-analysis': 'Historical Analysis', '/calibration-analytics': 'Calibration / Model Analytics', '/alert-dashboard': 'Alert Dashboard', '/critical-alert-timeline': 'Critical Alert Timeline', '/admin-alert-details': 'Alert Details', '/alert-ack': 'Alert Acknowledgement', '/alert-escalation': 'Alert Escalation', '/alert-rules': 'Alert Rules', '/devices': 'Device Dashboard', '/device-details': 'Device Details', '/register-device': 'Register Device', '/device-assignment': 'Device Assignment', '/device-diagnostics': 'Device Diagnostics', '/device-history': 'Device History', '/live-map': 'Live Worker Map', '/worker-location': 'Worker Location Details', '/zones': 'Zone Monitoring', '/admin-location-history': 'Location History', '/geofences': 'Geofence Management', '/report-dashboard': 'Report Dashboard', '/generate-report': 'Generate Report', '/admin-report-preview': 'Report Preview', '/scheduled-reports': 'Scheduled Reports', '/report-history': 'Report History', '/csv-export': 'CSV Export', '/pdf-export': 'PDF Export', '/organization-settings': 'Organization Settings', '/site-management': 'Site Management', '/zone-management': 'Zone Management', '/user-management': 'User Management', '/roles-permissions': 'Roles & Permissions', '/safety-thresholds': 'Safety Thresholds', '/notification-config': 'Notification Configuration', '/audit-logs': 'Audit Logs', '/system-health': 'System Health', '/api-status': 'API / Service Status', '/database-status': 'Database Status', '/storage-monitoring': 'Storage Monitoring', '/error-logs': 'Error Logs', '/security-logs': 'Security Logs', '/model-management': 'Model / Version Management', '/calibration-datasets': 'Calibration Dataset Management', '/backup-export': 'Backup / Export Management', '/system-config': 'System Configuration', '/documentation': 'Help / Documentation', '/about': 'About / Version', '/maintenance': 'Maintenance Mode', '/audit-log-details': 'Audit Log Details',
  },
};

final Map<String, ScreenBuilder> routeBuilders = {
  '/welcome': (s) => WelcomeScreen(state: s),
  '/login': (s) => LoginScreen(state: s, admin: false),
  '/admin-login': (s) => LoginScreen(state: s, admin: true),
  '/register': (s) => FormScreen(title: 'Worker Registration', fields: const ['Employee ID', 'Name', 'Email', 'Phone', 'Organization', 'Site', 'Password'], action: 'Create account', state: s),
  '/forgot-password': (s) => FormScreen(title: 'Forgot Password', fields: const ['Email / Employee ID'], action: 'Send reset link', state: s),
  '/reset-password': (s) => FormScreen(title: 'Password Reset', fields: const ['New password', 'Confirm password'], action: 'Reset password', state: s),
  '/dashboard': (s) => WorkerDashboard(state: s),
  '/scan-instructions': (s) => ScanInstructions(state: s),
  '/scan-method': (s) => ScanMethod(state: s),
  '/camera': (s) => ScannerScreen(state: s, mode: ImageSource.camera),
  '/image-review': (s) => ImageReview(state: s),
  '/result': (s) => ResultScreen(state: s),
  '/history': (s) => HistoryScreen(state: s),
  '/analytics': (s) => AnalyticsScreen(state: s, admin: false),
  '/alert-center': (s) => AlertsScreen(state: s, admin: false),
  '/notifications': (s) => NotificationsScreen(state: s),
  '/profile': (s) => ProfileScreen(state: s),
  '/settings': (s) => SettingsScreen(state: s),
  '/current-location': (s) => LocationScreen(state: s),
  '/reports': (s) => ReportsScreen(state: s, admin: false),
  '/export': (s) => ExportScreen(state: s),
  '/admin-dashboard': (s) => AdminDashboard(state: s),
  '/workers': (s) => WorkersScreen(state: s),
  '/exposure-trends': (s) => AnalyticsScreen(state: s, admin: true),
  '/risk-analytics': (s) => AnalyticsScreen(state: s, admin: true),
  '/critical-alert-timeline': (s) => AlertsScreen(state: s, admin: true),
  '/devices': (s) => DevicesScreen(state: s),
  '/live-map': (s) => LiveMapScreen(state: s),
  '/report-dashboard': (s) => ReportsScreen(state: s, admin: true),
  '/csv-export': (s) => ExportScreen(state: s),
  '/pdf-export': (s) => ExportScreen(state: s),
  '/profile': (s) => ProfileScreen(state: s),
  '/settings': (s) => SettingsScreen(state: s),
};

class Shell extends StatelessWidget {
  final String title; final Widget child; final AppState state; final bool admin;
  const Shell({super.key, required this.title, required this.child, required this.state, this.admin = false});
  @override Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 700;
    final items = admin ? const [('/admin-dashboard', 'Dashboard', Icons.dashboard), ('/workers', 'Workers', Icons.groups), ('/critical-alert-timeline', 'Alerts', Icons.warning_amber), ('/devices', 'Devices', Icons.memory), ('/live-map', 'Locations', Icons.map), ('/exposure-trends', 'Analytics', Icons.insights), ('/report-dashboard', 'Reports', Icons.description)] : const [('/dashboard','Home',Icons.home),('/scan-method','Scan',Icons.camera_alt),('/history','History',Icons.history),('/analytics','Analytics',Icons.insights),('/profile','Profile',Icons.person)];
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [IconButton(onPressed: state.toggleTheme, icon: Icon(state.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode)), IconButton(onPressed: () => Navigator.pushNamed(context, admin ? '/admin-security' : '/settings'), icon: const Icon(Icons.settings))]),
      drawer: mobile ? Drawer(child: SafeArea(child: ListView(children: [DrawerHeader(child: Text(admin ? 'H₂S Safety Admin' : 'H₂S Worker Safety', style: Theme.of(context).textTheme.headlineSmall)), ...items.map((e) => ListTile(leading: Icon(e.$3), title: Text(e.$2), onTap: () { Navigator.pop(context); Navigator.pushReplacementNamed(context, e.$1); }))])) : null,
      body: Row(children: [
        if (!mobile) SizedBox(width: 250, child: Material(color: Theme.of(context).colorScheme.surface, child: ListView(padding: const EdgeInsets.all(12), children: [Padding(padding: const EdgeInsets.all(16), child: Text(admin ? 'H₂S Safety Admin' : 'H₂S Worker Safety', style: Theme.of(context).textTheme.titleLarge)), ...items.map((e) => ListTile(leading: Icon(e.$3), title: Text(e.$2), selected: title == e.$2, onTap: () => Navigator.pushReplacementNamed(context, e.$1)))]))),
        Expanded(child: child),
      ]),
    );
  }
}

class WelcomeScreen extends StatelessWidget { final AppState state; const WelcomeScreen({super.key, required this.state}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Icon(Icons.shield, size: 80), const SizedBox(height: 20), Text('H₂S Safety Platform', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center), const SizedBox(height: 12), const Text('Worker safety, colorimetric strip decision support, alerts, analytics and operational monitoring.', textAlign: TextAlign.center), const SizedBox(height: 28), FilledButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Worker Login')), OutlinedButton(onPressed: () => Navigator.pushNamed(context, '/admin-login'), child: const Text('Admin / Manager Login')), const SizedBox(height: 18), Text('Prototype safety decision-support only — not a certified gas detector.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)])))); }

class LoginScreen extends StatefulWidget { final AppState state; final bool admin; const LoginScreen({super.key, required this.state, required this.admin}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> { final u = TextEditingController(); final p = TextEditingController(); @override Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(widget.admin ? 'Admin / Manager Login' : 'Worker Login', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 18), TextField(controller: u, decoration: const InputDecoration(labelText: 'Username / Email')), const SizedBox(height: 12), TextField(controller: p, obscureText: true, decoration: const InputDecoration(labelText: 'Password')), const SizedBox(height: 20), SizedBox(width: double.infinity, child: FilledButton(onPressed: () { widget.state.setRole(widget.admin ? 'Manager' : 'Worker'); widget.state.setUser(widget.admin ? 'Operations Manager' : 'Demo Worker'); Navigator.pushReplacementNamed(context, widget.admin ? '/admin-dashboard' : '/dashboard'); }, child: const Text('Sign in'))), if (!widget.admin) TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Create worker account')), TextButton(onPressed: () => Navigator.pushNamed(context, '/forgot-password'), child: const Text('Forgot password')), const SizedBox(height: 8), Text(widget.admin ? 'Demo: admin / admin123' : 'Demo: worker / 1234', style: Theme.of(context).textTheme.bodySmall)])))))))); }
}

class WorkerDashboard extends StatelessWidget { final AppState state; const WorkerDashboard({super.key, required this.state}); @override Widget build(BuildContext context) => Shell(title: 'Home', state: state, child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good afternoon, ${state.userName}', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 18), StatusCard(exposure: state.exposure, risk: state.risk), const SizedBox(height: 18), Wrap(spacing: 14, runSpacing: 14, children: [KpiCard(label:'Today’s Scans', value:'${state.scans.length}', icon:Icons.camera_alt), KpiCard(label:'Active Alerts', value:'${state.alerts.length}', icon:Icons.warning_amber), KpiCard(label:'Device', value:'Online', icon:Icons.smartphone), KpiCard(label:'Site', value:'Site A', icon:Icons.location_on)]), const SizedBox(height: 22), FilledButton.icon(onPressed: () => Navigator.pushNamed(context, '/scan-method'), icon: const Icon(Icons.camera_alt), label: const Padding(padding: EdgeInsets.all(12), child: Text('SCAN H₂S STRIP'))]))); }

class StatusCard extends StatelessWidget { final double exposure; final String risk; const StatusCard({super.key, required this.exposure, required this.risk}); @override Widget build(BuildContext context) { final c = risk == 'Critical' ? Colors.red : risk == 'Warning' ? Colors.amber.shade800 : Colors.green; return Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(width: 72,height:72, decoration: BoxDecoration(color:c.withOpacity(.12),shape:BoxShape.circle), child: Icon(Icons.shield, color:c, size:36)), const SizedBox(width:18), Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text('CURRENT SAFETY STATUS', style:Theme.of(context).textTheme.labelMedium), Text(risk.toUpperCase(), style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold,color:c)), Text('Exposure Index: ${exposure.round()} / 100')]))])); } }

class KpiCard extends StatelessWidget { final String label, value; final IconData icon; const KpiCard({super.key, required this.label, required this.value, required this.icon}); @override Widget build(BuildContext context) => SizedBox(width: 180, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon), const SizedBox(height: 10), Text(value, style: Theme.of(context).textTheme.headlineSmall), Text(label)])))); }

class ScanInstructions extends StatelessWidget { final AppState state; const ScanInstructions({super.key, required this.state}); @override Widget build(BuildContext context)=>Shell(title:'Scan',state:state,child:PageCard(title:'Quick scan instructions', children:[const InstructionStep(n:'1',text:'Prepare strip'),const InstructionStep(n:'2',text:'Place strip inside the capture guide'),const InstructionStep(n:'3',text:'Use sufficient, even lighting'),const InstructionStep(n:'4',text:'Capture the image'),const InstructionStep(n:'5',text:'Review analysis and risk'),FilledButton(onPressed:()=>Navigator.pushNamed(context,'/scan-method'),child:const Text('Continue'))])); }
class InstructionStep extends StatelessWidget { final String n,text; const InstructionStep({super.key,required this.n,required this.text}); @override Widget build(BuildContext c)=>ListTile(leading:CircleAvatar(child:Text(n)),title:Text(text)); }

class ScanMethod extends StatelessWidget { final AppState state; const ScanMethod({super.key, required this.state}); @override Widget build(BuildContext context)=>Shell(title:'Scan',state:state,child:PageCard(title:'Choose scan source',children:[SourceTile(icon:Icons.camera_alt,title:'Camera',subtitle:'Take a new strip photo',onTap:()=>Navigator.pushNamed(context,'/camera')),SourceTile(icon:Icons.photo_library,title:'Gallery',subtitle:'Select an existing strip image',onTap:()=>Navigator.pushNamed(context,'/camera',arguments:'gallery'))])); }
class SourceTile extends StatelessWidget { final IconData icon; final String title,subtitle; final VoidCallback onTap; const SourceTile({super.key,required this.icon,required this.title,required this.subtitle,required this.onTap}); @override Widget build(BuildContext c)=>Card(child:ListTile(leading:Icon(icon,size:34),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:onTap)); }

class ScannerScreen extends StatefulWidget { final AppState state; final ImageSource mode; const ScannerScreen({super.key,required this.state,required this.mode}); @override State<ScannerScreen> createState()=>_ScannerScreenState(); }
class _ScannerScreenState extends State<ScannerScreen> { bool busy=false; XFile? image; Future<void> pick(ImageSource src) async { setState(()=>busy=true); try { final picked=await ImagePicker().pickImage(source:src,imageQuality:92,maxWidth:1600); if(picked!=null){ image=picked; await analyze(picked); } } catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Camera/gallery error: $e'))); } finally { if(mounted)setState(()=>busy=false); } } Future<void> analyze(XFile x) async { final bytes=await x.readAsBytes(); final seed=bytes.fold<int>(0,(a,b)=>(a+b)%1000); final exposure=10+(seed%86).toDouble(); Position? pos; try{ final perm=await Geolocator.checkPermission(); if(perm==LocationPermission.denied) await Geolocator.requestPermission(); if(await Geolocator.isLocationServiceEnabled()) pos=await Geolocator.getCurrentPosition(); }catch(_){ } widget.state.setScan(value:exposure,image:x,position:pos); if(mounted) Navigator.pushReplacementNamed(context,'/result'); } @override Widget build(BuildContext context)=>Shell(title:'Camera',state:widget.state,child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[Expanded(child:Card(child:Center(child:busy?const CircularProgressIndicator():Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.camera_alt,size:90),const SizedBox(height:18),const Text('Position strip inside the guide'),const SizedBox(height:20),OutlinedButton.icon(onPressed:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt),label:const Text('Open Camera')),OutlinedButton.icon(onPressed:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library),label:const Text('Choose Gallery'))])))), const SizedBox(height:14), const Text('Image-quality and strip-detection validation should be added before production deployment.')]))); }
}

class ImageReview extends StatelessWidget { final AppState state; const ImageReview({super.key, required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Image Review',state:state,child:PageCard(title:'Captured image',children:[Text(state.lastImage?.name ?? 'No image selected'),FilledButton(onPressed:()=>Navigator.pushNamed(c,'/result'),child:const Text('Use image')),OutlinedButton(onPressed:()=>Navigator.pushNamed(c,'/camera'),child:const Text('Retake'))])); }

class ResultScreen extends StatelessWidget { final AppState state; const ResultScreen({super.key, required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Scan Result',state:state,child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(children:[StatusCard(exposure:state.exposure,risk:state.risk),const SizedBox(height:18),AnalysisTable(exposure:state.exposure),const SizedBox(height:18),Row(children:[Expanded(child:FilledButton(onPressed:()=>Navigator.pushNamed(c,'/scan-confirmation'),child:const Text('Save Scan'))),const SizedBox(width:12),Expanded(child:OutlinedButton(onPressed:()=>Navigator.pushNamed(c,'/camera'),child:const Text('Retake')))]), if(state.risk=='Critical') Padding(padding:const EdgeInsets.only(top:18),child:Card(child:ListTile(leading:const Icon(Icons.warning,color:Colors.red),title:const Text('Immediate action required'),subtitle:const Text('Critical classification is a prototype decision-support result. Follow your site emergency procedure.'))))])); }
}
class AnalysisTable extends StatelessWidget { final double exposure; const AnalysisTable({super.key,required this.exposure}); @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Color analysis',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:12),...['RGB Mean','HSV Hue / Sat / Value','Lab L* / a* / b*','DeltaE','Exposure Index','Confidence','Model Version','Calibration Version'].asMap().entries.map((e)=>ListTile(dense:true,title:Text(e.value),trailing:Text(e.key==4?exposure.round().toString():e.key==5?'0.86':e.key==6?'prototype-v1':'Recorded')))]))); }

class HistoryScreen extends StatelessWidget { final AppState state; const HistoryScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'History',state:state,child:ListView.separated(padding:const EdgeInsets.all(20),itemCount:state.scans.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i){final x=state.scans[i]; return Card(child:ListTile(leading:RiskBadge(label:x['risk']),title:Text('Exposure ${x['exposure']}'),subtitle:Text('${x['time']} • ${x['site']}'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.pushNamed(c,'/scan-details'));});})); }
class RiskBadge extends StatelessWidget { final String label; const RiskBadge({super.key,required this.label}); @override Widget build(BuildContext c){final color=label=='Critical'?Colors.red:label=='Warning'?Colors.amber.shade800:Colors.green;return Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(20)),child:Text(label,style:TextStyle(color:color,fontWeight:FontWeight.bold)));} }

class AnalyticsScreen extends StatelessWidget { final AppState state; final bool admin; const AnalyticsScreen({super.key,required this.state,required this.admin}); @override Widget build(BuildContext c)=>Shell(title:admin?'Analytics':'Analytics',state:state,admin:admin,child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(admin?'Exposure trends':'My exposure analytics',style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:18),Card(child:SizedBox(height:280,padding:const EdgeInsets.all(18),child:LineChart(LineChartData(minY:0,maxY:100,gridData:const FlGridData(show:true),titlesData:const FlTitlesData(show:false),borderData:FlBorderData(show:false),lineBarsData:[LineChartBarData(isCurved:true,spots:const [FlSpot(0,18),FlSpot(1,27),FlSpot(2,62),FlSpot(3,31),FlSpot(4,22),FlSpot(5,44),FlSpot(6,18)],barWidth:4,dotData:const FlDotData(show:true))]))),const SizedBox(height:18),Wrap(spacing:12,runSpacing:12,children:[KpiCard(label:'Daily Average',value:'31',icon:Icons.today),KpiCard(label:'Warnings',value:'4',icon:Icons.warning),KpiCard(label:'Critical',value:'1',icon:Icons.dangerous),KpiCard(label:'Scans',value:'28',icon:Icons.camera_alt)]),])); }

class AlertsScreen extends StatelessWidget { final AppState state; final bool admin; const AlertsScreen({super.key,required this.state,required this.admin}); @override Widget build(BuildContext c)=>Shell(title:'Alerts',state:state,admin:admin,child:ListView.separated(padding:const EdgeInsets.all(20),itemCount:state.alerts.length+1,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i){if(i==0)return Text(admin?'Critical alert timeline':'Alert Center',style:Theme.of(c).textTheme.headlineSmall);final a=state.alerts[i-1];return Card(child:ListTile(leading:RiskBadge(label:a['level']),title:Text(a['title']),subtitle:Text('${a['worker']} • ${a['location']}'),trailing:Text('${a['exposure']}'),onTap:()=>Navigator.pushNamed(c,admin?'/admin-alert-details':'/alert-details'));});})); }

class NotificationsScreen extends StatelessWidget { final AppState state; const NotificationsScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Notifications',state:state,child:ListView(padding:const EdgeInsets.all(20),children:const [ListTile(leading:Icon(Icons.notification_important),title:Text('Critical alert'),subtitle:Text('Immediate action required')),ListTile(leading:Icon(Icons.info),title:Text('Device sync'),subtitle:Text('Device connected successfully'))])); }

class ProfileScreen extends StatelessWidget { final AppState state; const ProfileScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Profile',state:state,child:PageCard(title:'Worker profile',children:[const CircleAvatar(radius:42,child:Icon(Icons.person,size:42)),const SizedBox(height:14),InfoRow('Name',state.userName),InfoRow('Employee ID','EMP-0104'),InfoRow('Role',state.role),InfoRow('Organization','Demo Industrial Services'),InfoRow('Site','Site A'),FilledButton(onPressed:()=>Navigator.pushNamed(c,'/edit-profile'),child:const Text('Edit profile'))])); }
class InfoRow extends StatelessWidget { final String a,b; const InfoRow(this.a,this.b,{super.key}); @override Widget build(BuildContext c)=>ListTile(title:Text(a),trailing:Text(b)); }
class SettingsScreen extends StatelessWidget { final AppState state; const SettingsScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Settings',state:state,child:ListView(padding:const EdgeInsets.all(20),children:[SwitchListTile(value:state.themeMode==ThemeMode.dark,onChanged:(_)=>state.toggleTheme(),title:const Text('Dark mode')),const ListTile(title:Text('Language'),trailing:Text('English')),const ListTile(title:Text('Notifications'),trailing:Text('Enabled')),const ListTile(title:Text('Location policy'),trailing:Text('On scan / alert'))])); }

class LocationScreen extends StatefulWidget { final AppState state; const LocationScreen({super.key,required this.state}); @override State<LocationScreen> createState()=>_LocationScreenState(); }
class _LocationScreenState extends State<LocationScreen> { bool loading=false; Future<void> locate() async { setState(()=>loading=true); try{if(!await Geolocator.isLocationServiceEnabled()) throw Exception('Location services are disabled'); var p=await Geolocator.checkPermission(); if(p==LocationPermission.denied)p=await Geolocator.requestPermission(); if(p==LocationPermission.denied||p==LocationPermission.deniedForever)throw Exception('Location permission denied'); widget.state.lastPosition=await Geolocator.getCurrentPosition(); widget.state.notifyListeners();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}finally{if(mounted)setState(()=>loading=false);} } @override Widget build(BuildContext c)=>Shell(title:'Locations',state:widget.state,child:PageCard(title:'Current location',children:[Text(widget.state.lastPosition==null?'Location not captured yet':'Lat ${widget.state.lastPosition!.latitude.toStringAsFixed(6)}\nLng ${widget.state.lastPosition!.longitude.toStringAsFixed(6)}\nAccuracy ${widget.state.lastPosition!.accuracy.toStringAsFixed(1)} m'),FilledButton(onPressed:loading?null:locate,child:Text(loading?'Reading GPS…':'Capture current location'))])); }

class ReportsScreen extends StatelessWidget { final AppState state; final bool admin; const ReportsScreen({super.key,required this.state,required this.admin}); @override Widget build(BuildContext c)=>Shell(title:'Reports',state:state,admin:admin,child:PageCard(title:admin?'Reporting platform':'My reports',children:[const ListTile(title:Text('Daily exposure report')),const ListTile(title:Text('Weekly exposure report')),const ListTile(title:Text('Monthly summary')),FilledButton(onPressed:()=>Navigator.pushNamed(c,'/export'),child:const Text('Export PDF / CSV'))])); }

class ExportScreen extends StatelessWidget { final AppState state; const ExportScreen({super.key,required this.state}); Future<Uint8List> makePdf() async { final doc=pw.Document(); doc.addPage(pw.Page(build:(_)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text('H₂S Exposure Report',style:pw.TextStyle(fontSize:24)),pw.SizedBox(height:16),pw.Text('Worker: ${state.userName}'),pw.Text('Risk: ${state.risk}'),pw.Text('Exposure Index: ${state.exposure.round()}'),pw.Text('Generated: ${DateTime.now()}'),pw.SizedBox(height:18),pw.Text('Prototype decision-support report.')]))); return doc.save(); } Future<void> csvExport(BuildContext context){ final rows=[['Timestamp','Worker','Site','Exposure','Risk'],...state.scans.map((x)=>[x['time'],state.userName,x['site'],x['exposure'],x['risk']])]; final out=const ListToCsvConverter().convert(rows); showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('CSV export ready'),content:SizedBox(width:600,child:SingleChildScrollView(child:SelectableText(out))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close'))])); return Future.value(); } @override Widget build(BuildContext c)=>Shell(title:'Export',state:state,child:PageCard(title:'Report export',children:[FilledButton.icon(onPressed:()async{final bytes=await makePdf(); await Printing.layoutPdf(onLayout:(_)=>bytes);},icon:const Icon(Icons.picture_as_pdf),label:const Text('Generate / Print PDF')),OutlinedButton.icon(onPressed:()=>csvExport(c),icon:const Icon(Icons.table_chart),label:const Text('Generate CSV'))])); }

class AdminDashboard extends StatelessWidget { final AppState state; const AdminDashboard({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Dashboard',state:state,admin:true,child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Operations overview',style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:16),Wrap(spacing:14,runSpacing:14,children:[KpiCard(label:'Workers Online',value:'124',icon:Icons.groups),KpiCard(label:'Active Devices',value:'118',icon:Icons.memory),KpiCard(label:"Today's Scans",value:'486',icon:Icons.camera_alt),KpiCard(label:'Warnings',value:'17',icon:Icons.warning),KpiCard(label:'Critical Alerts',value:'3',icon:Icons.dangerous)]),const SizedBox(height:18),AnalyticsPreview(),const SizedBox(height:18),Card(child:Column(children:[const ListTile(title:Text('Critical alert timeline')),const ListTile(leading:RiskBadge(label:'Critical'),title:Text('Worker 104'),subtitle:Text('Processing Area 3')),const ListTile(leading:RiskBadge(label:'Warning'),title:Text('Worker 087'),subtitle:Text('Tank Area'))]))])); }
class AnalyticsPreview extends StatelessWidget { @override Widget build(BuildContext c)=>Card(child:SizedBox(height:260,padding:const EdgeInsets.all(18),child:LineChart(LineChartData(minY:0,maxY:100,titlesData:const FlTitlesData(show:false),lineBarsData:[LineChartBarData(spots:const [FlSpot(0,18),FlSpot(1,31),FlSpot(2,48),FlSpot(3,42),FlSpot(4,67),FlSpot(5,56),FlSpot(6,72)],isCurved:true,barWidth:4)])))); } }

class WorkersScreen extends StatelessWidget { final AppState state; const WorkersScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Workers',state:state,admin:true,child:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Card(child:DataTable(columns:const [DataColumn(label:Text('Employee')),DataColumn(label:Text('Site')),DataColumn(label:Text('Risk')),DataColumn(label:Text('Device'))],rows:const [DataRow(cells:[DataCell(Text('EMP-0104')),DataCell(Text('Site A')),DataCell(Text('Critical')),DataCell(Text('Online'))]),DataRow(cells:[DataCell(Text('EMP-0087')),DataCell(Text('Site A')),DataCell(Text('Warning')),DataCell(Text('Online'))]),DataRow(cells:[DataCell(Text('EMP-0121')),DataCell(Text('Site B')),DataCell(Text('Safe')),DataCell(Text('Offline'))])])))); }

class DevicesScreen extends StatelessWidget { final AppState state; const DevicesScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Devices',state:state,admin:true,child:ListView(padding:const EdgeInsets.all(20),children:const [DeviceTile('DEV-104','EMP-0104','Online','89%'),DeviceTile('DEV-087','EMP-0087','Online','62%'),DeviceTile('DEV-121','EMP-0121','Offline','12%')])); }
class DeviceTile extends StatelessWidget { final String id,worker,status,battery; const DeviceTile(this.id,this.worker,this.status,this.battery,{super.key}); @override Widget build(BuildContext c)=>Card(child:ListTile(leading:const Icon(Icons.memory),title:Text(id),subtitle:Text('$worker • $status'),trailing:Text(battery))); }

class LiveMapScreen extends StatelessWidget { final AppState state; const LiveMapScreen({super.key,required this.state}); @override Widget build(BuildContext c)=>Shell(title:'Locations',state:state,admin:true,child:Card(margin:const EdgeInsets.all(20),child:Center(child:Padding(padding:const EdgeInsets.all(50),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.map,size:100),Text('Live worker map',style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:8),const Text('Map-provider abstraction ready. Connect Google Maps / MapLibre / another provider and bind realtime worker locations.')]))))); }

class FormScreen extends StatelessWidget { final String title,action; final List<String> fields; final AppState state; const FormScreen({super.key,required this.title,required this.fields,required this.action,required this.state}); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(title)),body:SingleChildScrollView(padding:const EdgeInsets.all(20),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:600),child:Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[...fields.map((x)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(decoration:InputDecoration(labelText:x)))),SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(c),child:Text(action)))]))))))); }

class PageCard extends StatelessWidget { final String title; final List<Widget> children; const PageCard({super.key,required this.title,required this.children}); @override Widget build(BuildContext c)=>SingleChildScrollView(padding:const EdgeInsets.all(20),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:900),child:Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:18),...children.map((x)=>Padding(padding:const EdgeInsets.only(bottom:12),child:x))]))))); }

class GenericScreen extends StatelessWidget { final String title; final AppState state; const GenericScreen({super.key,required this.title,required this.state}); @override Widget build(BuildContext c)=>Shell(title:title,state:state,admin:title.toLowerCase().contains('admin')||title.contains('Management')||title.contains('System')||title.contains('Device')||title.contains('Audit')||title.contains('Alert'),child:PageCard(title:title,children:[const Text('This route is included in the 64-screen architecture and is ready for the next implementation pass.'),const Text('Connect the corresponding Supabase repository, RLS policy, realtime stream, form validation and production service when this module is activated.'),OutlinedButton(onPressed:()=>Navigator.pop(c),child:const Text('Back'))])); }
