import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database_helper.dart';
import 'new_order_screen.dart';
import 'order_printer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProcurementApp());
}

class ProcurementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة طلبات الشراء',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Cairo',
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ar', 'SA'),
      ],
      locale: Locale('ar', 'SA'),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getOrders();
    setState(() {
      _orders = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات الشراء المرحلة'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text('لا توجد طلبات شراء مسجلة بعد'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (ctx, idx) {
                    final order = _orders[idx];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text("\${order['order_no']}"),
                        ),
                        title: Text("\${order['supplier']} - \${order['branch']}"),
                        subtitle: Text("التاريخ: \${order['order_date']} | المحرر: \${order['editor']}"),
                        trailing: IconButton(
                          icon: Icon(Icons.print, color: Colors.indigo),
                          onPressed: () async {
                            final items = await DatabaseHelper.instance.getOrderItems(order['order_no']);
                            await OrderPrinter.printOrder(order, items);
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text('طلب شراء جديد'),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => NewOrderScreen()),
          );
          if (res == true) _loadOrders();
        },
      ),
    );
  }
}
