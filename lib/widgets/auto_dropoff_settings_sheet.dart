import 'package:famzlog_flutter/services/auto_dropoff_service.dart';
import 'package:famzlog_flutter/widgets/modern_snackbar.dart';
import 'package:flutter/material.dart';

const _primary = Color(0xFF1580C1);

/// Shows the Auto Drop Off settings bottom sheet.
/// Returns the saved [AutoConfig] if saved, or null if dismissed.
Future<AutoConfig?> showAutoDropOffSettingsSheet(BuildContext context) async {
  final initial = await AutoDropOffService.loadConfig();

  if (!context.mounted) return null;

  return showModalBottomSheet<AutoConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AutoDropOffSettingsSheet(initial: initial),
  );
}

class _AutoDropOffSettingsSheet extends StatefulWidget {
  const _AutoDropOffSettingsSheet({required this.initial});
  final AutoConfig initial;

  @override
  State<_AutoDropOffSettingsSheet> createState() =>
      _AutoDropOffSettingsSheetState();
}

class _AutoDropOffSettingsSheetState extends State<_AutoDropOffSettingsSheet> {
  late bool _useCustom;
  late int _wait;
  late int _unload;
  late int _whOut;
  late int _whIn;

  @override
  void initState() {
    super.initState();
    _useCustom = widget.initial.useCustomSettings;
    _wait = widget.initial.waitMinutes;
    _unload = widget.initial.unloadMinutes;
    _whOut = widget.initial.warehouseOutMinutes;
    _whIn = widget.initial.warehouseInMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.auto_mode_rounded, color: _primary),
                SizedBox(width: 8),
                Text(
                  'Auto Drop Off',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Selalu aktif. Otomatis Process → Start → Finish ketika driver berada di radius 500m toko.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Toggle custom settings
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _useCustom
                    ? _primary.withOpacity(0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _useCustom
                      ? _primary.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gunakan Settingan Custom',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _useCustom ? _primary : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _useCustom
                              ? 'Menggunakan waktu dari slider di bawah'
                              : 'Menggunakan default: ${kAutoDropOffWaitMinutes}m process/start, ${kAutoDropOffFinishDelayMinutes}m finish',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _useCustom,
                    activeColor: _primary,
                    onChanged: (v) => setState(() => _useCustom = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sliders — only active when custom = true
            Opacity(
              opacity: _useCustom ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !_useCustom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sliderRow(
                      label: 'Waktu tunggu di radius sebelum Process & Start',
                      value: _wait,
                      min: 1,
                      max: 30,
                      color: _primary,
                      onChanged: (v) => setState(() => _wait = v),
                    ),
                    const SizedBox(height: 12),
                    _sliderRow(
                      label: 'Waktu unloading sebelum auto Finish',
                      value: _unload,
                      min: 1,
                      max: 60,
                      color: _primary,
                      onChanged: (v) => setState(() => _unload = v),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.warehouse_outlined,
                          size: 16,
                          color: _useCustom ? Colors.black87 : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pengaturan Warehouse',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _useCustom ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _sliderRow(
                      label:
                          'Waktu setelah keluar radius 500m DC sebelum auto Scan Out Warehouse',
                      value: _whOut,
                      min: 1,
                      max: 30,
                      color: Colors.teal,
                      onChanged: (v) => setState(() => _whOut = v),
                    ),
                    const SizedBox(height: 12),
                    _sliderRow(
                      label: 'Waktu di radius DC sebelum auto Scan Finish Trip',
                      value: _whIn,
                      min: 1,
                      max: 30,
                      color: Colors.indigo,
                      onChanged: (v) => setState(() => _whIn = v),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await AutoDropOffService.saveConfig(
                    useCustomSettings: _useCustom,
                    waitMinutes: _wait,
                    unloadMinutes: _unload,
                    warehouseOutMinutes: _whOut,
                    warehouseInMinutes: _whIn,
                  );
                  final saved = (
                    useCustomSettings: _useCustom,
                    waitMinutes: _wait,
                    unloadMinutes: _unload,
                    warehouseOutMinutes: _whOut,
                    warehouseInMinutes: _whIn,
                  );
                  if (context.mounted) {
                    showModernSnackBar(
                      context,
                      title: 'Berhasil',
                      message: _useCustom
                          ? 'Settingan custom aktif: ${_wait}m process/start, ${_unload}m finish'
                          : 'Menggunakan settingan default: ${kAutoDropOffWaitMinutes}m / ${kAutoDropOffFinishDelayMinutes}m',
                      success: true,
                    );
                    Navigator.pop(context, saved);
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _useCustom ? Colors.black54 : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                activeColor: color,
                label: '${value}m',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            Container(
              width: 52,
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value}m',
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
