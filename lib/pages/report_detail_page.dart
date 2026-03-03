import 'package:flutter/material.dart';
import 'package:famzlog_flutter/services/driver_dc_service.dart';
import 'dart:math';

class ReportDetailPage extends StatelessWidget {
  final DriverReportItem item;

  const ReportDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Detail Report',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildChartCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow('Date', item.date),
          _buildRow('Route', item.route),
          _buildRow('Checkout DC', item.checkoutDc),
          _buildRow('DC to 1st DP', item.dcTo1stDp),
          _buildRow('Idle Time', item.idleTime),
          _buildRow('Last DP to DC', item.lastDpToDc),
          const Divider(height: 24),
          _buildRow('Total Travel Time', item.travelTimeTotal, isBold: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final stats = item.storeStats;
    final total = stats.completed + stats.processing + stats.pending;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store Status Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (total > 0)
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: PieChartPainter(
                    completed: stats.completed,
                    processing: stats.processing,
                    pending: stats.pending,
                  ),
                ),
              ),
            )
          else
            const Center(child: Text('No store data available')),
          const SizedBox(height: 24),
          _buildLegendItem(Colors.green, 'Completed', stats.completed),
          _buildLegendItem(Colors.orange, 'Proses', stats.processing),
          _buildLegendItem(Colors.grey.shade300, 'Belum di proses', stats.pending),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final int completed;
  final int processing;
  final int pending;

  PieChartPainter({required this.completed, required this.processing, required this.pending});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final total = completed + processing + pending;
    
    if (total == 0) return;

    double startAngle = -pi / 2;
    
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 30;

    // Completed
    if (completed > 0) {
      final sweepAngle = (completed / total) * 2 * pi;
      paint.color = Colors.green;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 15), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Processing
    if (processing > 0) {
      final sweepAngle = (processing / total) * 2 * pi;
      paint.color = Colors.orange;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 15), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Pending
    if (pending > 0) {
      final sweepAngle = (pending / total) * 2 * pi;
      paint.color = Colors.grey.shade300;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 15), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
