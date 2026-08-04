import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/core/constants/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders exactly the syntax strola_health_super_admin_next's legal
/// document editor can produce ("# "/"## " headings, "**bold**", "- "
/// bullets, "1. " numbered lists, "[text](url)" links) — the Dart-side
/// equivalent of that admin panel's legal-markdown.tsx and the public
/// hosting page's functions/src/legal/legalPage.ts, kept in sync with the
/// same small syntax subset rather than pulling in a general markdown
/// package for four things.
class LegalMarkdown extends StatelessWidget {
  const LegalMarkdown({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');
    final blocks = <Widget>[];
    var i = 0;

    bool isBlockStart(String line) =>
        line.startsWith('# ') ||
        line.startsWith('## ') ||
        line.startsWith('- ') ||
        RegExp(r'^\d+\.\s').hasMatch(line);

    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        i++;
        continue;
      }
      if (line.startsWith('## ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: _inline(line.substring(3), AppTypography.titleM),
          ),
        );
        i++;
        continue;
      }
      if (line.startsWith('# ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: _inline(line.substring(2), AppTypography.titleL),
          ),
        );
        i++;
        continue;
      }
      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^\d+\.\s').hasMatch(lines[i])) {
          items.add(lines[i].replaceFirst(RegExp(r'^\d+\.\s'), ''));
          i++;
        }
        blocks.add(_list(items, ordered: true));
        continue;
      }
      if (line.startsWith('- ')) {
        final items = <String>[];
        while (i < lines.length && lines[i].startsWith('- ')) {
          items.add(lines[i].substring(2));
          i++;
        }
        blocks.add(_list(items, ordered: false));
        continue;
      }
      final paraLines = <String>[];
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !isBlockStart(lines[i])) {
        paraLines.add(lines[i]);
        i++;
      }
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _inline(
            paraLines.join(' '),
            AppTypography.bodyM.copyWith(height: 1.6),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _list(List<String> items, {required bool ordered}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var n = 0; n < items.length; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      ordered ? '${n + 1}.' : '•',
                      style: AppTypography.bodyM.copyWith(height: 1.6),
                    ),
                  ),
                  Expanded(
                    child: _inline(
                      items[n],
                      AppTypography.bodyM.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// "**bold**" and "[text](url)" within a line of otherwise-plain text.
  Widget _inline(String text, TextStyle base) {
    final pattern = RegExp(r'(\*\*(.+?)\*\*)|(\[([^\]]+)\]\(([^)]+)\))');
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(3) != null) {
        final label = match.group(4)!;
        final url = match.group(5)!;
        spans.add(
          TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.accent,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                final uri = Uri.tryParse(url);
                if (uri != null)
                  launchUrl(uri, mode: LaunchMode.externalApplication);
              },
          ),
        );
      }
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return RichText(
      text: TextSpan(
        style: base.copyWith(color: AppColors.textPrimary),
        children: spans,
      ),
    );
  }
}
