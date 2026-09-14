import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class CreateTicketTab extends ConsumerStatefulWidget {
  const CreateTicketTab({super.key});

  @override
  ConsumerState<CreateTicketTab> createState() => _CreateTicketTabState();
}

class _CreateTicketTabState extends ConsumerState<CreateTicketTab> {
  final _formKey = GlobalKey<FormState>();

  final _operatorCtrl = TextEditingController();
  final _subDomainCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<TextEditingController> _imageCtrls =
      List.generate(6, (_) => TextEditingController());

  bool _android = false;
  bool _ios = false;
  bool _isSubmitting = false;
  String? _appTypeError;

  @override
  void dispose() {
    _operatorCtrl.dispose();
    _subDomainCtrl.dispose();
    _websiteCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final c in _imageCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearForm() {
    _operatorCtrl.clear();
    _subDomainCtrl.clear();
    _websiteCtrl.clear();
    _descriptionCtrl.clear();
    for (final c in _imageCtrls) {
      c.clear();
    }
    setState(() {
      _android = false;
      _ios = false;
      _appTypeError = null;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _appTypeError =
          (!_android && !_ios) ? 'Select at least one app type' : null;
    });
    if (!formValid || _appTypeError != null) return;

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    final appType =
        (_android && _ios) ? 'both' : (_android ? 'android' : 'ios');

    setState(() => _isSubmitting = true);
    final success = await ref.read(ticketListProvider.notifier).createTicket(
          operatorName: _operatorCtrl.text.trim(),
          subDomain: _subDomainCtrl.text.trim(),
          website: _websiteCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          imageUrls: _imageCtrls.map((c) => c.text.trim()).toList(),
          appType: appType,
          createdBy: userId,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appType == 'both'
                ? 'Created 2 tickets (Android + iOS)'
                : 'Ticket created',
          ),
        ),
      );
      _clearForm();
    } else {
      final error =
          ref.read(ticketListProvider).error ?? 'Could not create ticket';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New ticket',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Capture the app details so the team can start quickly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  context,
                  icon: Icons.business_outlined,
                  title: 'Project details',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _operatorCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Operator name',
                          hintText: 'e.g. City Transit',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _subDomainCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Sub-domain',
                          hintText: 'e.g. city-transit',
                          prefixIcon: Icon(Icons.language_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'What needs to be built or changed?',
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
                  icon: Icons.devices_outlined,
                  title: 'Target platforms',
                  subtitle: 'Choose at least one platform.',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _platformTile(
                              context,
                              label: 'Android',
                              icon: Icons.android,
                              selected: _android,
                              onTap: () => setState(() => _android = !_android),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _platformTile(
                              context,
                              label: 'iOS',
                              icon: Icons.phone_iphone_outlined,
                              selected: _ios,
                              onTap: () => setState(() => _ios = !_ios),
                            ),
                          ),
                        ],
                      ),
                      if (_appTypeError != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _appTypeError!,
                            style: TextStyle(color: colors.error, fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selecting both creates two separate tickets, each with its own ID.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'Reference images',
                  subtitle: 'Add up to 6 image links. These are optional.',
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
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task),
                    label: Text(
                        _isSubmitting ? 'Creating ticket...' : 'Create ticket'),
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

  Widget _platformTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surface,
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? colors.primary : colors.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
