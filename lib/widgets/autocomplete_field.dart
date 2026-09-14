import 'package:flutter/material.dart';

/// A text field that suggests previously-used values (team names, sites,
/// supervisors, ...) as the technician types, but always accepts free text —
/// the same "type-ahead, never blocks entry" pattern as the web app's
/// <input list="..."> fields.
class AutocompleteField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> suggestions;
  final TextEditingController controller;
  final bool required;

  const AutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.suggestions,
    required this.controller,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF4E5D68))),
        ),
        RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue value) {
            if (value.text.isEmpty) return suggestions.take(8);
            final q = value.text.toLowerCase();
            return suggestions.where((s) => s.toLowerCase().contains(q)).take(8);
          },
          fieldViewBuilder: (context, textController, focusNode, onSubmit) {
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: InputDecoration(hintText: hint),
              validator: required
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                  : null,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(9),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, minWidth: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final opt = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        title: Text(opt, style: const TextStyle(fontSize: 14)),
                        onTap: () => onSelected(opt),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
