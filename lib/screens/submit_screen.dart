import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';
import '../services/photo_service.dart';
import '../theme.dart';
import '../widgets/autocomplete_field.dart';

class SubmitScreen extends StatefulWidget {
  final List<FieldEntry> entries;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const SubmitScreen({super.key, required this.entries, required this.onSubmit});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _date = DateTime.now();
  final _teamCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();
  final _tasksCtrl = TextEditingController();
  final _issueTextCtrl = TextEditingController();
  final _followUpOwnerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _status;
  bool _hasIssue = false;
  String _severity = 'none';
  bool _followUp = false;
  bool _showNotes = false;
  bool _submitting = false;
  String _submitLabel = 'Submit Update';

  final List<XFile> _photos = [];
  final ImagePicker _picker = ImagePicker();

  static const _durationPresets = [
    '1 day', '2 days', '3 days', '4 days', '1 week', '2 weeks', '3 weeks', '1 month', '2+ months'
  ];
  static const _ownerPresets = ['Office', 'Project Manager', 'Safety Coordinator'];

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teamCtrl.text = prefs.getString('dsg_team') ?? '';
      _siteCtrl.text = prefs.getString('dsg_site') ?? '';
      _supervisorCtrl.text = prefs.getString('dsg_sup') ?? '';
    });
  }

  List<String> _uniqueSorted(Iterable<String> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in values) {
      final v = raw.trim();
      if (v.isNotEmpty && seen.add(v)) out.add(v);
    }
    out.sort();
    return out;
  }

  Future<void> _addFromCamera() async {
    final shot = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 70);
    if (shot != null) setState(() => _photos.add(shot));
  }

  Future<void> _addFromGallery() async {
    final picked = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 70);
    if (picked.isNotEmpty) setState(() => _photos.addAll(picked));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Site Photos  *'),
        const Padding(
          padding: EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            'At least one photo is required with every entry.',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ),
        if (_photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_photos.length, (i) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photos[i].path),
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => _removePhoto(i),
                        child: Container(
                          decoration: const BoxDecoration(color: AppColors.crit, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addFromCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Choose Photos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = _uniqueSorted(widget.entries.map((e) => e.team));
    final sites = _uniqueSorted(widget.entries.map((e) => e.site));
    final sups = _uniqueSorted(widget.entries.map((e) => e.supervisor));
    final owners = _uniqueSorted([..._ownerPresets, ...widget.entries.map((e) => e.followUpOwner)]);
    final durations = _uniqueSorted([..._durationPresets, ...widget.entries.map((e) => e.duration)]);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Field Log', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              const Text('Direct Services Group', style: TextStyle(color: AppColors.inkMuted, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dateField(),
                      const SizedBox(height: 14),
                      AutocompleteField(label: 'Estimated Build Duration', hint: 'e.g. 3 days', suggestions: durations, controller: _durationCtrl, required: true),
                      const SizedBox(height: 14),
                      AutocompleteField(label: 'Team / Crew Name', hint: 'e.g. Crew 4 - Underground', suggestions: teams, controller: _teamCtrl, required: true),
                      const SizedBox(height: 14),
                      AutocompleteField(label: 'Job Site / Location', hint: 'e.g. Maple Ave Substation', suggestions: sites, controller: _siteCtrl, required: true),
                      const SizedBox(height: 14),
                      AutocompleteField(label: 'Supervisor / Lead', hint: 'Your name', suggestions: sups, controller: _supervisorCtrl, required: true),
                      const SizedBox(height: 14),
                      _label('Tasks Completed Today'),
                      TextFormField(
                        controller: _tasksCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(hintText: 'What did the crew get done today?'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Status'),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['on_track', 'ahead', 'behind', 'complete'].map((s) {
                          final on = _status == s;
                          return ChoiceChip(
                            label: Text(statusLabel(s)),
                            selected: on,
                            onSelected: (_) => setState(() => _status = s),
                            selectedColor: statusSoft(s),
                            labelStyle: TextStyle(
                              color: on ? statusColor(s) : AppColors.inkSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            side: BorderSide(color: on ? statusColor(s) : AppColors.border),
                            backgroundColor: AppColors.surfaceSunk,
                          );
                        }).toList(),
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Any issues or safety concerns today?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Leave off for a normal, no-issue day', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _hasIssue,
                            onChanged: (v) => setState(() => _hasIssue = v),
                          ),
                        ],
                      ),
                      if (_hasIssue) ...[
                        const SizedBox(height: 10),
                        _label('Describe it'),
                        TextFormField(
                          controller: _issueTextCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Delay, damaged materials, near-miss, incident...'),
                        ),
                        const SizedBox(height: 14),
                        _label('Severity'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['none', 'low', 'medium', 'high_safety'].map((s) {
                            final on = _severity == s;
                            return ChoiceChip(
                              label: Text(severityLabel(s)),
                              selected: on,
                              onSelected: (_) => setState(() => _severity = s),
                              selectedColor: severitySoft(s),
                              labelStyle: TextStyle(
                                color: on ? severityColor(s) : AppColors.inkSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              side: BorderSide(color: on ? severityColor(s) : AppColors.border),
                              backgroundColor: AppColors.surfaceSunk,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Follow-up required', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            Switch(value: _followUp, onChanged: (v) => setState(() => _followUp = v)),
                          ],
                        ),
                        if (_followUp) ...[
                          const SizedBox(height: 8),
                          AutocompleteField(label: 'Follow-up owner', hint: "Who's handling it?", suggestions: owners, controller: _followUpOwnerCtrl),
                        ],
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _showNotes = !_showNotes),
                        style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
                        child: Text(_showNotes ? '– Hide note' : '+ Add a note', style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600)),
                      ),
                      if (_showNotes) ...[
                        const SizedBox(height: 6),
                        _label('Notes'),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Anything else worth flagging'),
                        ),
                      ],
                      const Divider(height: 32),
                      _photoSection(),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: Text(_submitting ? _submitLabel : 'Submit Update'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Fields with suggestions remember past entries — start typing to pick one, or type something new.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
      );

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date'),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime.now().subtract(const Duration(days: 60)),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (picked != null) setState(() => _date = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Text(DateFormat('MM/dd/yyyy').format(_date)),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_status == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a status before submitting')));
      return;
    }
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one site photo before submitting')));
      return;
    }
    setState(() {
      _submitting = true;
      _submitLabel = 'Uploading photos…';
    });

    List<String> photoUrls;
    try {
      photoUrls = await PhotoService.uploadAll(_photos.map((x) => File(x.path)).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't upload photos — check your connection and try again")));
        setState(() => _submitting = false);
      }
      return;
    }

    if (mounted) setState(() => _submitLabel = 'Submitting…');

    final payload = {
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'team': _teamCtrl.text.trim(),
      'site': _siteCtrl.text.trim(),
      'duration': _durationCtrl.text.trim(),
      'supervisor': _supervisorCtrl.text.trim(),
      'tasks': _tasksCtrl.text.trim(),
      'status': _status,
      'hasIssue': _hasIssue,
      'issueText': _hasIssue ? _issueTextCtrl.text.trim() : '',
      'severity': _hasIssue ? _severity : 'none',
      'followUp': _hasIssue ? _followUp : false,
      'followUpOwner': (_hasIssue && _followUp) ? _followUpOwnerCtrl.text.trim() : '',
      'notes': _notesCtrl.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'photoUrls': photoUrls,
    };

    try {
      await widget.onSubmit(payload);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dsg_team', payload['team'] as String);
      await prefs.setString('dsg_site', payload['site'] as String);
      await prefs.setString('dsg_sup', payload['supervisor'] as String);
      _resetForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update submitted ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't save — check your connection and try again")));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _date = DateTime.now();
      _durationCtrl.clear();
      _tasksCtrl.clear();
      _issueTextCtrl.clear();
      _followUpOwnerCtrl.clear();
      _notesCtrl.clear();
      _status = null;
      _hasIssue = false;
      _severity = 'none';
      _followUp = false;
      _showNotes = false;
      _photos.clear();
      _submitLabel = 'Submit Update';
      // team/site/supervisor intentionally kept — same crew usually logs again tomorrow
    });
  }
}
