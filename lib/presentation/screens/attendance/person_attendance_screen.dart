import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/attendance_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';





class PersonAttendanceScreen extends StatefulWidget {
  final String personId;
  final String name;
  final String email;
  final String phone;
  final String nationalId;
  final String roleLabel;

  const PersonAttendanceScreen({
    super.key,
    required this.personId,
    required this.name,
    required this.email,
    required this.phone,
    required this.nationalId,
    required this.roleLabel,
  });

  @override
  State<PersonAttendanceScreen> createState() => _PersonAttendanceScreenState();
}

class _PersonAttendanceScreenState extends State<PersonAttendanceScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _loading = true;
  Set<String> _presentDates = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prov = Provider.of<AttendanceProvider>(context, listen: false);
    final dates = await prov.fetchPersonAttendanceDates(widget.personId);
    if (mounted) {
      setState(() {
        _presentDates = dates;
        _loading = false;
      });
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colors = AppColors.of(context);
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    final firstDayOfMonth = _visibleMonth;
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;



    final leadingBlanks = firstDayOfMonth.weekday - 1;

    final presentThisMonth = _presentDates.where((k) {
      final parts = k.split('-');
      if (parts.length != 3) return false;
      return int.tryParse(parts[0]) == _visibleMonth.year &&
          int.tryParse(parts[1]) == _visibleMonth.month;
    }).length;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryBlue),
        title: Text(widget.name, style: TextStyle(color: colors.textColor)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _infoCard(colors, loc),
                const SizedBox(height: 16),
                _summaryCard(colors, loc),
                const SizedBox(height: 16),
                _calendarCard(colors, loc, today, todayKey, daysInMonth, leadingBlanks, presentThisMonth),
              ],
            ),
    );
  }

  Widget _infoCard(AppColors colors, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colors.primaryBlue.withOpacity(0.15),
                child: Icon(Icons.person, color: colors.primaryBlue, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: TextStyle(
                            color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.roleLabel, style: TextStyle(color: colors.subTextColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(loc.translate('personalInfo'),
              style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          _infoRow(colors, Icons.email_outlined, widget.email.isEmpty ? loc.translate('notProvided') : widget.email),
          _infoRow(colors, Icons.phone_outlined, widget.phone.isEmpty ? loc.translate('notProvided') : widget.phone),
          _infoRow(
              colors, Icons.badge_outlined, widget.nationalId.isEmpty ? loc.translate('notProvided') : widget.nationalId,
              label: loc.translate('nationalId')),
        ],
      ),
    );
  }

  Widget _infoRow(AppColors colors, IconData icon, String value, {String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.subTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label != null ? '$label: $value' : value,
              style: TextStyle(color: colors.textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(AppColors colors, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: colors.primaryBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(loc.translate('totalAttendanceDays'),
              style: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600)),
          Text('${_presentDates.length}',
              style: TextStyle(color: colors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _calendarCard(AppColors colors, AppLocalizations loc, DateTime today, String todayKey,
      int daysInMonth, int leadingBlanks, int presentThisMonth) {
    final weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: colors.primaryBlue),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${_visibleMonth.year} - ${_visibleMonth.month.toString().padLeft(2, '0')}',
                style: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: colors.primaryBlue),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          Text('$presentThisMonth ${loc.translate('presentStatus')}',
              style: TextStyle(color: colors.subTextColor, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: weekdayLabels
                .map((w) => Expanded(
                      child: Center(
                        child: Text(w, style: TextStyle(color: colors.subTextColor, fontSize: 11)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + leadingBlanks,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (ctx, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final key = _dateKey(date);
              final isPresent = _presentDates.contains(key);
              final isToday = key == todayKey;
              final isFuture = date.isAfter(today);

              Color bg;
              Color fg;
              if (isPresent) {
                bg = colors.accentGreen;
                fg = Colors.white;
              } else if (isFuture) {
                bg = colors.borderColor.withOpacity(0.4);
                fg = colors.subTextColor;
              } else {
                bg = Colors.redAccent.withOpacity(0.15);
                fg = Colors.redAccent;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: colors.primaryBlue, width: 1.6) : null,
                ),
                alignment: Alignment.center,
                child: Text('$day', style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            children: [
              _legendDot(colors.accentGreen, loc.translate('presentStatus'), colors),
              _legendDot(Colors.redAccent.withOpacity(0.6), loc.translate('absentStatus'), colors),
              _legendDot(colors.borderColor, loc.translate('futureStatus'), colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, AppColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: colors.subTextColor, fontSize: 12)),
      ],
    );
  }
}