import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends an email notification via Web3Forms whenever a new Field Log
/// entry is submitted.
///
/// This is fire-and-forget on purpose: the Firestore write in main.dart
/// is the real submission and has already succeeded by the time this
/// runs, so if Web3Forms is briefly down or the phone has no signal,
/// we swallow the error instead of showing the technician a failure
/// for something that isn't actually their problem.
class NotifyService {
  // Web3Forms access key for Direct Services Group's Field Log form.
  // This is a public key (safe to ship in the app) — it only lets
  // someone submit TO this form, not read anything back.
  static const String _accessKey = '80181da5-4859-4d18-80c9-7158f3c20ff4';

  static const Map<String, String> _statusLabels = {
    'on_track': 'On Track',
    'ahead': 'Ahead of Schedule',
    'behind': 'Behind Schedule',
    'complete': 'Complete',
  };

  static const Map<String, String> _severityLabels = {
    'none': 'None',
    'low': 'Low',
    'medium': 'Medium',
    'high_safety': 'HIGH — Safety Concern',
  };

  static Future<void> notifyNewEntry(Map<String, dynamic> payload) async {
    try {
      final hasIssue = payload['hasIssue'] == true;
      final status = _statusLabels[payload['status']] ?? (payload['status']?.toString() ?? '');
      final severity = _severityLabels[payload['severity']] ?? (payload['severity']?.toString() ?? '');
      final team = (payload['team'] ?? '').toString();
      final site = (payload['site'] ?? '').toString();

      final lines = <String>[
        'Date: ${payload['date'] ?? ''}',
        'Team: $team',
        'Site: $site',
        'Supervisor: ${payload['supervisor'] ?? ''}',
        'Estimated Duration: ${payload['duration'] ?? ''}',
        'Status: $status',
        '',
        'Tasks Completed:',
        (payload['tasks'] ?? '').toString(),
      ];

      if (hasIssue) {
        lines.addAll([
          '',
          'ISSUE REPORTED — Severity: $severity',
          (payload['issueText'] ?? '').toString(),
        ]);
        if (payload['followUp'] == true) {
          final owner = (payload['followUpOwner'] as String?) ?? '';
          lines.add('Follow-up required — Owner: ${owner.isNotEmpty ? owner : 'unassigned'}');
        }
      }

      final notes = (payload['notes'] as String?) ?? '';
      if (notes.isNotEmpty) {
        lines.addAll(['', 'Notes: $notes']);
      }

      final photoUrls = ((payload['photoUrls'] as List?) ?? const []).map((e) => e.toString()).toList();
      if (photoUrls.isNotEmpty) {
        lines.add('');
        lines.add(photoUrls.length == 1 ? 'Photo:' : 'Photos (${photoUrls.length}):');
        for (final url in photoUrls) {
          lines.add(url);
        }
      }

      final isHighSafety = hasIssue && payload['severity'] == 'high_safety';
      final subject = isHighSafety
          ? '⚠ HIGH SAFETY ISSUE — $team at $site'
          : 'Field Log: $team at $site — $status';

      final body = {
        'access_key': _accessKey,
        'subject': subject,
        'from_name': 'Field Log App',
        'message': lines.join('\n'),
      };

      final response = await http.post(
        Uri.parse('https://api.web3forms.com/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('Web3Forms notification failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Never let a notification failure surface to the technician —
      // their entry is already safely saved in Firestore.
      // ignore: avoid_print
      print('Web3Forms notification error: $e');
    }
  }
}
