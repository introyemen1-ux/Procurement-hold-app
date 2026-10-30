import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderPrinter {
  static Future<void> printOrder(Map<String, dynamic> order, List<Map<String, dynamic>> items) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.cairoRegular(),
          bold: await PdfGoogleFonts.cairoBold(),
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("أمر شراء - PURCHASE ORDER",
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("طلب شراء رقم: \${order['order_no']}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text("التاريخ: \${order['order_date']}"),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الفرع: \${order['branch']}"),
                    pw.Text("المورد: \${order['supplier']}"),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("القسم: \${order['department']}"),
                    pw.Text("المحرر: \${order['editor']}"),
                  ],
                ),
                pw.Divider(height: 20),
                pw.Table.fromTextArray(
                  headers: ['م', 'رقم الصنف', 'وصف الصنف', 'الوحدة', 'الكمية', 'السعر', 'المبلغ'],
                  data: items.asMap().entries.map((e) {
                    final item = e.value;
                    return [
                      (e.key + 1).toString(),
                      item['item_code'],
                      item['description'],
                      item['unit'],
                      item['quantity'].toString(),
                      item['unit_price'].toString(),
                      item['total'].toString(),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.center,
                ),
                pw.SizedBox(height: 15),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    "المبلغ الإجمالي: \${items.fold(0.0, (s, i) => s + (i['total'] as double)).toStringAsFixed(2)} ر.س",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
