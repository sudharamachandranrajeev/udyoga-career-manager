// Regenerates assets/soc/soc2020_index.tsv.gz: every job title of the ONS SOC
// 2020 coding index (Volume 2), each with its SOC 2020 unit group and the
// ISCO-08 code ONS gives it, plus the unit group titles. Contains public
// sector information licensed under the Open Government Licence v3.0.
//
//   dart run tool/gen_soc_index.dart [path/to/coding-index.xlsx]
//
// Without a path it downloads the index from ONS. Keep the raw download out
// of the repo; only the compressed asset is committed.
//
// The asset is gzip-compressed, tab-separated UTF-8 text:
//   # comment lines (source, licence, version)
//   U <tab> unit group <tab> unit group title
//   T <tab> job title in lower case <tab> unit group <tab> ISCO-08 <tab> flag
// The flag is '' for a plain index title and 'q' for a title ONS lists only
// with a qualifier or an industry ("manager (hospital)"): it is a real title
// in that unit group, but not on its own.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

const indexPage =
    'https://www.ons.gov.uk/methodology/classificationsandstandards/standardoccupationalclassificationsoc/'
    'soc2020/soc2020volume2codingrulesandconventions';
const indexFile =
    'https://www.ons.gov.uk/file?uri=/methodology/classificationsandstandards/standardoccupationalclassificationsoc/'
    'soc2020/soc2020volume2codingrulesandconventions/soc2020volume2thecodingindexexcel20260827v4.xlsx';

/// Where the asset goes, from the repo root.
const assetPath = 'assets/soc/soc2020_index.tsv.gz';

/// "AB12" to its column index (AB = 27, zero based 27).
int _column(String ref) {
  var n = 0;
  for (final c in ref.replaceAll(RegExp(r'\d'), '').codeUnits) {
    n = n * 26 + (c - 64);
  }
  return n - 1;
}

String _clean(String s) => s.replaceAll(RegExp(r'[\t\r\n]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

Future<void> main(List<String> args) async {
  final bytes = args.isNotEmpty
      ? await File(args.first).readAsBytes()
      : (await http.get(Uri.parse(indexFile), headers: {'User-Agent': 'udyoga-tool'})).bodyBytes;
  final zip = ZipDecoder().decodeBytes(bytes);
  String read(String name) => utf8.decode(zip.findFile(name)!.content as List<int>);

  final shared = [
    for (final si in XmlDocument.parse(read('xl/sharedStrings.xml')).findAllElements('si'))
      si.findAllElements('t').map((t) => t.innerText).join(),
  ];
  // The version line on the INFO sheet ("Version 14 Of The Standard ...").
  final version = RegExp(r'Version (\d+) Of The Standard').firstMatch(shared.join('\n'))?[1] ?? '?';

  // The sheet named "SOC2020 coding index", through the workbook's rels.
  final workbook = XmlDocument.parse(read('xl/workbook.xml'));
  final rid = workbook
      .findAllElements('sheet')
      .firstWhere((s) => s.getAttribute('name') == 'SOC2020 coding index')
      .attributes
      .firstWhere((a) => a.name.local == 'id')
      .value;
  final target = XmlDocument.parse(read('xl/_rels/workbook.xml.rels'))
      .findAllElements('Relationship')
      .firstWhere((r) => r.getAttribute('Id') == rid)
      .getAttribute('Target')!;
  final sheet = XmlDocument.parse(read('xl/${target.replaceFirst(RegExp('^/?xl/'), '')}'));

  List<String> cells(XmlElement row) {
    final out = <String>[];
    for (final c in row.findElements('c')) {
      final i = _column(c.getAttribute('r')!);
      while (out.length <= i) {
        out.add('');
      }
      final v = c.getElement('v')?.innerText ?? c.findAllElements('t').map((t) => t.innerText).join();
      out[i] = c.getAttribute('t') == 's' && v.isNotEmpty ? shared[int.parse(v)] : v;
    }
    return out;
  }

  final rows = sheet.findAllElements('row').map(cells).toList();
  final head = rows.first.map((h) => h.trim()).toList();
  int col(String name) {
    final i = head.indexOf(name);
    if (i < 0) throw StateError('No column "$name" in $head');
    return i;
  }

  final soc = col('SOC_2020'), isco = col('ISCO-08 code based on SOC2020');
  final add = col('ADD'), ind = col('IND'), title = col('INDEXOCC_-_natural_word_order');
  final unit = col('SOC2020_unit_group_title');
  String at(List<String> r, int i) => i < r.length ? _clean(r[i]) : '';

  // (title, soc) -> [isco, flag]; a plain row wins over a qualified one.
  final entries = <String, List<String>>{};
  final units = <String, String>{};
  for (final r in rows.skip(1)) {
    final code = at(r, soc);
    if (!RegExp(r'^\d{4}$').hasMatch(code)) continue;
    final t = at(r, title).toLowerCase();
    if (t.isEmpty) continue;
    final plain = at(r, add).isEmpty && at(r, ind).isEmpty;
    final key = '$t\t$code';
    final had = entries[key];
    if (had == null || (plain && had[1] == 'q')) {
      entries[key] = [at(r, isco), plain ? '' : 'q'];
    }
    if (at(r, unit).isNotEmpty) units[code] = at(r, unit);
  }
  final keys = entries.keys.toList()..sort();

  final out = StringBuffer()
    ..writeln('# ONS SOC 2020 Volume 2: the coding index, version $version (file of 27 August 2026, v4)')
    ..writeln('# $indexPage')
    ..writeln('# Contains public sector information licensed under the Open Government Licence v3.0.')
    ..writeln('# GENERATED by tool/gen_soc_index.dart; do not edit.');
  for (final e in (units.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
    out.writeln('U\t${e.key}\t${e.value}');
  }
  for (final k in keys) {
    final v = entries[k]!;
    out.writeln('T\t$k\t${v[0]}\t${v[1]}');
  }
  final gz = GZipEncoder().encode(utf8.encode(out.toString()), level: 9);
  await File(assetPath).create(recursive: true);
  await File(assetPath).writeAsBytes(gz);
  final plain = entries.values.where((v) => v[1].isEmpty).length;
  stdout.writeln(
    'Wrote ${keys.length} titles ($plain plain) in ${units.length} unit groups '
    '(index version $version) to $assetPath, ${gz.length} bytes',
  );
}
