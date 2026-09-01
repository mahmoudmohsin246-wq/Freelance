import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/subscription_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  late AppColors _colors;
  Color get scaffoldBg => _colors.scaffoldBg;
  Color get cardBg => _colors.cardBg;
  Color get primaryBlue => _colors.primaryBlue;
  Color get accentGreen => _colors.accentGreen;
  Color get textColor => _colors.textColor;
  Color get subTextColor => _colors.subTextColor;
  MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualCodeController = TextEditingController();
  bool _processing = false;
  String? _lastMessage;
  Color _lastMessageColor = const Color(0xFF10B981);

  void _recreateController() {
    final old = _controller;
    setState(() {
      _controller = MobileScannerController();
    });
    old.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String code) async {
    if (_processing || code.trim().isEmpty) return;
    setState(() => _processing = true);

    final loc = AppLocalizations.of(context);
    final subProv = Provider.of<SubscriptionProvider>(context, listen: false);
    final attendanceProv = Provider.of<AttendanceProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    final trimmedCode = code.trim();
    final match = subProv.subscriptions
        .where((s) => s.attendanceCode.trim().isNotEmpty && s.attendanceCode.trim() == trimmedCode)
        .toList();

    if (match.isEmpty) {
      setState(() {
        _lastMessage = loc.translate('codeNotRecognized');
        _lastMessageColor = Colors.redAccent;
      });
    } else {
      final player = match.first;
      // Key attendance by the player's Firebase account id (userId) when the
      // subscription is linked to a real account, so history follows the
      // person across subscription renewals. Falls back to the subscription
      // id for older/unlinked subscriptions.
      final personId = player.userId.trim().isNotEmpty ? player.userId : player.id;
      final isNew = await attendanceProv.recordAttendance(
        personId: personId,
        personName: player.playerName,
        personEmail: player.userEmail,
        academyName: authProv.currentUser?.academyName ?? '',
      );
      setState(() {
        _lastMessage = isNew
            ? '${loc.translate('attendanceRecorded')} ${player.playerName}'
            : '${player.playerName} ${loc.translate('alreadyCheckedInToday')}';
        _lastMessageColor = isNew ? accentGreen : Colors.orangeAccent;
      });
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    _colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text(loc.translate('scanAttendance'), style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final value = barcodes.first.rawValue;
                      if (value != null) {
                        _handleCode(value);
                      }
                    }
                  },
                  errorBuilder: (context, error) {
                    return Container(
                      color: Colors.black,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'خطأ في فتح الكاميرا:\n'
                              '${error.errorCode}\n'
                              '${error.errorDetails?.message ?? ""}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _recreateController,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة محاولة فتح الكاميرا'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = (constraints.maxWidth < constraints.maxHeight
                              ? constraints.maxWidth
                              : constraints.maxHeight) *
                          0.6;
                      final boxSize = side.clamp(160.0, 280.0);
                      return Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryBlue, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.translate('pointCameraAtCode'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: _lastMessageColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _lastMessageColor),
                      ),
                      child: Text(
                        _lastMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _lastMessageColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(loc.translate('manualCodeEntry'),
                      style: TextStyle(color: subTextColor, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCodeController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cardBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: scaffoldBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          _handleCode(_manualCodeController.text);
                          _manualCodeController.clear();
                        },
                        child: Text(loc.translate('submitCode')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
