import 'package:cloud_firestore/cloud_firestore.dart';

class FieldEntry {
  final String id;
  final String date; // yyyy-MM-dd
  final String team;
  final String site;
  final String duration;
  final String supervisor;
  final String tasks;
  final String status; // on_track | ahead | behind | complete
  final bool hasIssue;
  final String issueText;
  final String severity; // none | low | medium | high_safety
  final bool followUp;
  final String followUpOwner;
  final String notes;
  final String createdAt;
  final List<String> photoUrls;

  FieldEntry({
    required this.id,
    required this.date,
    required this.team,
    required this.site,
    required this.duration,
    required this.supervisor,
    required this.tasks,
    required this.status,
    required this.hasIssue,
    required this.issueText,
    required this.severity,
    required this.followUp,
    required this.followUpOwner,
    required this.notes,
    required this.createdAt,
    this.photoUrls = const [],
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'team': team,
        'site': site,
        'duration': duration,
        'supervisor': supervisor,
        'tasks': tasks,
        'status': status,
        'hasIssue': hasIssue,
        'issueText': issueText,
        'severity': severity,
        'followUp': followUp,
        'followUpOwner': followUpOwner,
        'notes': notes,
        'createdAt': createdAt,
        'photoUrls': photoUrls,
      };

  factory FieldEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FieldEntry(
      id: doc.id,
      date: (d['date'] ?? '') as String,
      team: (d['team'] ?? '') as String,
      site: (d['site'] ?? '') as String,
      duration: (d['duration'] ?? '') as String,
      supervisor: (d['supervisor'] ?? '') as String,
      tasks: (d['tasks'] ?? '') as String,
      status: (d['status'] ?? '') as String,
      hasIssue: (d['hasIssue'] ?? false) as bool,
      issueText: (d['issueText'] ?? '') as String,
      severity: (d['severity'] ?? 'none') as String,
      followUp: (d['followUp'] ?? false) as bool,
      followUpOwner: (d['followUpOwner'] ?? '') as String,
      notes: (d['notes'] ?? '') as String,
      createdAt: (d['createdAt'] ?? '') as String,
      photoUrls: ((d['photoUrls'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
