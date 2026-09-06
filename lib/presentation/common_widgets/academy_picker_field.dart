import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';





class AcademyPickerField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> academyNames;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const AcademyPickerField({
    super.key,
    required this.hint,
    required this.value,
    required this.academyNames,
    required this.onChanged,
    this.isLoading = false,
    this.errorText,
  });

  Future<void> _openPicker(BuildContext context) async {
    final colors = AppColors.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AcademySearchSheet(academyNames: academyNames, colors: colors),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isLoading ? null : () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.cardBg,
          prefixIcon: Icon(Icons.sports_soccer_outlined, color: colors.subTextColor, size: 20),
          suffixIcon: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primaryBlue),
                  ),
                )
              : Icon(Icons.keyboard_arrow_down_rounded, color: colors.subTextColor),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colors.primaryBlue, width: 1.5),
          ),
        ),
        child: Text(
          value == null || value!.isEmpty ? hint : value!,
          style: GoogleFonts.inter(
            color: value == null || value!.isEmpty ? colors.subTextColor.withOpacity(0.6) : colors.textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _AcademySearchSheet extends StatefulWidget {
  final List<String> academyNames;
  final AppColors colors;

  const _AcademySearchSheet({required this.academyNames, required this.colors});

  @override
  State<_AcademySearchSheet> createState() => _AcademySearchSheetState();
}

class _AcademySearchSheetState extends State<_AcademySearchSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered = widget.academyNames;

  void _filter(String query) {
    setState(() {
      _filtered = widget.academyNames
          .where((name) => name.toLowerCase().contains(query.trim().toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _filter,
                  style: GoogleFonts.inter(color: colors.textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الأكاديمية...',
                    hintStyle: GoogleFonts.inter(color: colors.subTextColor.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.subTextColor),
                    filled: true,
                    fillColor: colors.scaffoldBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          widget.academyNames.isEmpty ? 'لا توجد أكاديميات مسجلة بعد' : 'لا يوجد نتائج مطابقة',
                          style: GoogleFonts.inter(color: colors.subTextColor, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderColor),
                        itemBuilder: (_, index) {
                          final name = _filtered[index];
                          return ListTile(
                            leading: Icon(Icons.sports_soccer_outlined, color: colors.primaryBlue, size: 20),
                            title: Text(name, style: GoogleFonts.inter(color: colors.textColor, fontSize: 14)),
                            onTap: () => Navigator.of(context).pop(name),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}