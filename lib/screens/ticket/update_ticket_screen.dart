import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/api_exception.dart';
import '../../models/ticket_model.dart';

class UpdateTicketScreen extends StatefulWidget {
  final Ticket ticket;

  const UpdateTicketScreen({super.key, required this.ticket});

  @override
  State<UpdateTicketScreen> createState() => _UpdateTicketScreenState();
}

class _UpdateTicketScreenState extends State<UpdateTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _operatorCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _descriptionCtrl;
  late final List<TextEditingController> _imageCtrls;
  late String _status;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.ticket;
    _operatorCtrl = TextEditingController(text: t.operatorName);
    _websiteCtrl = TextEditingController(text: t.website ?? '');
    _descriptionCtrl = TextEditingController(text: t.description ?? '');
    _imageCtrls = [
      TextEditingController(text: t.imageUrl1 ?? ''),
      TextEditingController(text: t.imageUrl2 ?? ''),
      TextEditingController(text: t.imageUrl3 ?? ''),
      TextEditingController(text: t.imageUrl4 ?? ''),
      TextEditingController(text: t.imageUrl5 ?? ''),
      TextEditingController(text: t.imageUrl6 ?? ''),
    ];
    _status = t.status;
  }

  @override
  void dispose() {
    _operatorCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final c in _imageCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.updateTicket(
        ticketNumber: widget.ticket.ticketNumber!,
        operatorName: _operatorCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        imageUrls: _imageCtrls.map((c) => c.text.trim()).toList(),
        status: _status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket updated')),
      );
      Navigator.of(context).pop(true); // true = tell Dashboard to refresh
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not reach the server. Check your connection.'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.ticketNumber ?? 'Update ticket'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _save,
            tooltip: 'Save changes',
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit ticket',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Update the ticket details and keep its progress current.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    context,
                    icon: Icons.confirmation_number_outlined,
                    title: 'Ticket identity',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _infoChip(context, Icons.tag_outlined,
                            t.ticketNumber ?? 'No ticket ID'),
                        _infoChip(
                            context, Icons.language_outlined, t.subDomain),
                        _infoChip(context, Icons.devices_outlined, t.appType),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    icon: Icons.edit_note_outlined,
                    title: 'Ticket details',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _operatorCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Operator name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _websiteCtrl,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Website / domain',
                            hintText: 'https://example.com',
                            prefixIcon: Icon(Icons.link_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Add context for the team',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 58),
                              child: Icon(Icons.notes_outlined),
                            ),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    icon: Icons.track_changes_outlined,
                    title: 'Progress',
                    subtitle: 'Keep everyone aligned on the current stage.',
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: kTicketStatuses
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _status = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    icon: Icons.photo_library_outlined,
                    title: 'Reference images',
                    subtitle: 'Update up to 6 image links. These are optional.',
                    child: Column(
                      children: [
                        for (var i = 0; i < _imageCtrls.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          TextFormField(
                            controller: _imageCtrls[i],
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'Image ${i + 1}',
                              hintText: 'Paste an image URL',
                              prefixIcon: const Icon(Icons.image_outlined),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                          _isSaving ? 'Saving changes...' : 'Save changes'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18, color: colors.primary),
      label: Text(label),
      backgroundColor: colors.surface,
      side: BorderSide(color: colors.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
