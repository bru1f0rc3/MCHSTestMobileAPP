import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mchs_mobile_app/features/admin/data/models/report_model.dart';

class ReportPdfBuilder {
  ReportPdfBuilder._();
  static Future<Uint8List> build(DetailedReportDto report) async {
    final doc = pw.Document(
      title: _titleFor(report),
      author: 'МЧС — Система тестирования',
      subject: 'Отчёт по результатам тестирования',
    );

    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final italic = await PdfGoogleFonts.notoSansItalic();

    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
        header: (ctx) =>
            ctx.pageNumber == 1 ? _firstHeader(report) : _runningHeader(report),
        footer: _footer,
        build: (ctx) => [_participantsTable(report)],
      ),
    );

    return doc.save();
  }

  static pw.Widget _firstHeader(DetailedReportDto r) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Сформировано: ${_fmtDateTime(r.generatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 0.8, color: PdfColors.grey500),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              _titleFor(r).toUpperCase(),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              _subtitleFor(r),
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _runningHeader(DetailedReportDto r) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Сформировано: ${_fmtDateTime(r.generatedAt)}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Документ сформирован автоматически. Система МЧС.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Стр. ${ctx.pageNumber} из ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _participantsTable(DetailedReportDto r) {
    final header = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
        color: PdfColors.grey200,
      ),
      child: pw.Text(
        'Список попыток прохождения',
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );

    if (r.results.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          header,
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'По выбранным фильтрам записей не найдено.',
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    final headers = [
      '№',
      'ФИО / Логин',
      'Тест',
      'Начат',
      'Время',
      'Балл',
      'Статус',
      'Подозр.',
    ];

    final data = <List<String>>[];
    for (var i = 0; i < r.results.length; i++) {
      final row = r.results[i];
      final person = row.fullName != null && row.fullName!.isNotEmpty
          ? '${row.fullName}\n${row.username}'
          : row.username;

      final scoreText = row.score != null
          ? '${row.score!.toStringAsFixed(1)}%'
          : '—';

      final durationText = _buildDurationLabel(
        row.durationSeconds,
        row.timeLimitMinutes,
      );

      data.add([
        (i + 1).toString(),
        person,
        row.testTitle,
        _fmtDateTime(row.startedAt),
        durationText,
        scoreText,
        _statusLabel(row.status) + (row.autoSubmitted ? '\n(авто)' : ''),
        row.cheatAttempts > 0 ? row.cheatAttempts.toString() : '—',
      ]);
    }

    final table = pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
        fontSize: 8.5,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headerHeight: 22,
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: const {
        0: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.center,
        7: pw.Alignment.center,
      },
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(2.6),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FixedColumnWidth(56),
        5: pw.FixedColumnWidth(40),
        6: pw.FixedColumnWidth(60),
        7: pw.FixedColumnWidth(42),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [header, pw.SizedBox(height: 6), table],
    );
  }

  static String _titleFor(DetailedReportDto r) {
    switch (r.kind) {
      case 'date':
        return 'Отчёт по дате';
      case 'period':
        return 'Отчёт за период';
      case 'test':
        return 'Отчёт по тесту';
      case 'test_period':
        return 'Отчёт по тесту за период';
      default:
        return 'Отчёт о тестировании';
    }
  }

  static String _subtitleFor(DetailedReportDto r) {
    final parts = <String>[];
    if (r.startDate != null && r.endDate != null) {
      if (r.startDate!.toLocal().day == r.endDate!.toLocal().day &&
          r.startDate!.toLocal().month == r.endDate!.toLocal().month &&
          r.startDate!.toLocal().year == r.endDate!.toLocal().year) {
        parts.add('за ${_fmtDate(r.startDate!)}');
      } else {
        parts.add('с ${_fmtDate(r.startDate!)} по ${_fmtDate(r.endDate!)}');
      }
    } else if (r.startDate != null) {
      parts.add('с ${_fmtDate(r.startDate!)}');
    } else if (r.endDate != null) {
      parts.add('по ${_fmtDate(r.endDate!)}');
    }
    if (r.testTitle != null && r.testTitle!.isNotEmpty) {
      parts.add('«${r.testTitle!}»');
    }
    if (parts.isEmpty) return 'Все зафиксированные попытки системы';
    return parts.join(' · ');
  }

  static String _buildDurationLabel(int? seconds, int? limitMinutes) {
    if (seconds == null) return '—';
    final elapsed = _fmtSeconds(seconds);
    if (limitMinutes == null || limitMinutes <= 0) return elapsed;
    final limitStr = _fmtSeconds(limitMinutes * 60);
    return '$elapsed\nиз $limitStr';
  }

  static String _fmtSeconds(int totalSec) {
    if (totalSec < 0) totalSec = 0;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    if (h > 0) return '$h:${two(m)}:${two(s)}';
    return '$m:${two(s)}';
  }

  static String _fmtDate(DateTime v) {
    final local = v.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }

  static String _fmtDateTime(DateTime v) {
    final local = v.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'passed':
        return 'Сдан';
      case 'failed':
        return 'Не сдан';
      case 'in_progress':
      case 'in-progress':
        return 'В процессе';
      case 'completed':
        return 'Завершён';
      default:
        return raw;
    }
  }
}
