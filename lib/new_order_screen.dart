import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class NewOrderScreen extends StatefulWidget {
  @override
  _NewOrderScreenState createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final TextEditingController _orderNoController = TextEditingController();
  String _selectedBranch = 'فرع جدة';
  String _selectedDepartment = 'مستودع قطع غيار السيارات';
  String _selectedSupplier = 'مؤسسة عبد الرحمن الشايع';
  String _selectedEditor = 'السيد / حسن علي';
  String _selectedDirector = 'السيد / خبور خير';
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _orderNoController.text = (1000 + DateTime.now().minute * 10 + DateTime.now().second).toString();
  }

  double get _totalAmount =>
      _orderItems.fold(0.0, (sum, item) => sum + (item['total'] as double));

  void _addItemDialog() async {
    List<Map<String, dynamic>> itemsList = await DatabaseHelper.instance.searchItems('');
    Map<String, dynamic>? selectedItem;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إضافة صنف للطلب', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'اختر الصنف'),
                  items: itemsList.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text("\${item['item_code']} - \${item['description']}",
                          style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedItem = val;
                      priceController.text = (val?['unit_price'] ?? 0.0).toString();
                    });
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: qtyController,
                  decoration: InputDecoration(labelText: 'الكمية المطلوبة'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'سعر الوحدة'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedItem != null) {
                  double qty = double.tryParse(qtyController.text) ?? 1.0;
                  double price = double.tryParse(priceController.text) ?? 0.0;
                  setState(() {
                    _orderItems.add({
                      'item_code': selectedItem!['item_code'],
                      'description': selectedItem!['description'],
                      'unit': selectedItem!['unit'],
                      'quantity': qty,
                      'unit_price': price,
                      'total': qty * price,
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveOrder() async {
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء إضافة أصناف أولاً للطلب')),
      );
      return;
    }

    int orderNumber = int.tryParse(_orderNoController.text) ?? 1005;

    await DatabaseHelper.instance.insertOrder({
      'order_no': orderNumber,
      'order_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'branch': _selectedBranch,
      'department': _selectedDepartment,
      'supplier': _selectedSupplier,
      'editor': _selectedEditor,
      'director': _selectedDirector,
      'status': 'مرحل',
    }, _orderItems);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم ترحيل الطلب بنجاح رقم: \$orderNumber')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('طلب شراء جديد')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _orderNoController,
                              decoration: InputDecoration(labelText: 'رقم الطلب'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "التاريخ: \${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBranch,
                              decoration: InputDecoration(labelText: 'الفرع'),
                              items: ['فرع جدة', 'فرع الرياض', 'فرع الدمام', 'فرع حائل', 'فرع مكة', 'فرع المدينة المنورة', 'فرع أبها']
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedBranch = v!),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSupplier,
                              decoration: InputDecoration(labelText: 'المورد'),
                              items: [
                                'مؤسسة عبد الرحمن الشايع',
                                'الشركة العربية السعودية لزيوت التشحيم',
                                'الشركة المتحدة لزيوت التشحيم',
                                'شركة الصافي',
                                'شركة المنصور للنقليات',
                                'شركة زياد العالمية',
                                'مؤسسة عبد العزيز الفريح'
                              ].map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                               .toList(),
                              onChanged: (v) => setState(() => _selectedSupplier = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: _orderItems.isEmpty
                    ? Center(child: Text("لا توجد أصناف مضافة. اضغط 'إضافة صنف' للبدء"))
                    : ListView.separated(
                        itemCount: _orderItems.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = _orderItems[idx];
                          return ListTile(
                            title: Text("\${item['description']} (\${item['item_code']})"),
                            subtitle: Text("الكمية: \${item['quantity']} \${item['unit']} × \${item['unit_price']}"),
                            trailing: Text("\${item['total']} ر.س", style: TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("الإجمالي: \${_totalAmount.toStringAsFixed(2)} ر.س",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('إضافة صنف'),
                          onPressed: _addItemDialog,
                        ),
                        SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: Icon(Icons.check),
                          label: Text('ترحيل'),
                          onPressed: _saveOrder,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
