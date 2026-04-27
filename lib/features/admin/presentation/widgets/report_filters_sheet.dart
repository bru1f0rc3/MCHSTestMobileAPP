import 'package:flutter/material.dart';
import 'package:mchs_mobile_app/core/theme/app_theme.dart';
import 'package:mchs_mobile_app/features/testing/data/models/test_model.dart';

class ReportFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? testId;
  final String? testTitle;

  const ReportFilters({
    this.startDate,
    this.endDate,
    this.testId,
    this.testTitle,
  });

  bool get isEmpty => startDate == null && endDate == null && testId == null;
  String describe() {
    final parts = <String>[];
    if (startDate != null) parts.add('с ${_fmtDate(startDate!)}');
    if (endDate != null) parts.add('по ${_fmtDate(endDate!)}');
    if (testId != null && (testTitle?.isNotEmpty ?? false)) {
      parts.add('тест: $testTitle');
    }
    return parts.isEmpty ? 'без фильтров' : parts.join(', ');
  }

  static String _fmtDate(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }
}

Future<ReportFilters?> showReportFiltersSheet(
  BuildContext context, {
  required ReportFilters initial,
  required List<TestModel> availableTests,
}) {
  return showModalBottomSheet<ReportFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) =>
        _FiltersSheet(initial: initial, availableTests: availableTests),
  );
}

class _FiltersSheet extends StatefulWidget {
  final ReportFilters initial;
  final List<TestModel> availableTests;

  const _FiltersSheet({required this.initial, required this.availableTests});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late DateTime? _start;
  late DateTime? _end;
  late int? _testId;

  @override
  void initState() {
    super.initState();
    _start = widget.initial.startDate;
    _end = widget.initial.endDate;
    _testId = widget.initial.testId;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _start : _end) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: isStart ? 'Начальная дата' : 'Конечная дата',
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end != null && _end!.isBefore(_start!)) {
          _end = null;
        }
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_start != null && _end!.isBefore(_start!)) {
          _start = null;
        }
      }
    });
  }

  void _applyQuickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final s = now.subtract(Duration(days: days - 1));
      _start = DateTime(s.year, s.month, s.day);
    });
  }

  void _reset() {
    setState(() {
      _start = null;
      _end = null;
      _testId = null;
    });
  }

  void _apply() {
    TestModel? selected;
    if (_testId != null) {
      try {
        selected = widget.availableTests.firstWhere((t) => t.id == _testId);
      } catch (_) {
        selected = null;
      }
    }
    Navigator.of(context).pop(
      ReportFilters(
        startDate: _start,
        endDate: _end,
        testId: _testId,
        testTitle: selected?.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Фильтры отчёта',
              style: AppTypography.heading4.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Период',
              style: AppTypography.body2.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateChip(
                    label: 'С',
                    date: _start,
                    onTap: () => _pickDate(isStart: true),
                    onClear: _start == null
                        ? null
                        : () => setState(() => _start = null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateChip(
                    label: 'По',
                    date: _end,
                    onTap: () => _pickDate(isStart: false),
                    onClear: _end == null
                        ? null
                        : () => setState(() => _end = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickRangeChip(
                  label: 'Сегодня',
                  onTap: () => _applyQuickRange(1),
                ),
                _QuickRangeChip(
                  label: '7 дней',
                  onTap: () => _applyQuickRange(7),
                ),
                _QuickRangeChip(
                  label: '30 дней',
                  onTap: () => _applyQuickRange(30),
                ),
                _QuickRangeChip(
                  label: '90 дней',
                  onTap: () => _applyQuickRange(90),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Тест',
              style: AppTypography.body2.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _testId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.surfaceVariantColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              dropdownColor: context.surfaceColor,
              iconEnabledColor: context.textSecondaryColor,
              style: TextStyle(color: context.textPrimaryColor),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'Все тесты',
                    style: TextStyle(color: context.textPrimaryColor),
                  ),
                ),
                ...widget.availableTests.map(
                  (t) => DropdownMenuItem<int?>(
                    value: t.id,
                    child: Text(
                      t.title,
                      style: TextStyle(color: context.textPrimaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _testId = v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                    ),
                    child: const Text('Сбросить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateChip({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = date == null ? 'Выбрать' : ReportFilters._fmtDate(date!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaceVariantColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: context.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: context.textTertiaryColor,
                    ),
                  ),
                  Text(
                    text,
                    style: AppTypography.body2.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: context.textTertiaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickRangeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickRangeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: context.primaryColor.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: context.primaryColor),
      side: BorderSide(color: context.primaryColor.withValues(alpha: 0.3)),
    );
  }
}
