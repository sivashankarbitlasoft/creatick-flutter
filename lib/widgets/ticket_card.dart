import 'package:flutter/material.dart';

import '../models/ticket_model.dart';

class _AppTypeTheme {
  final Color primary;
  final Color light;
  const _AppTypeTheme(this.primary, this.light);
}

_AppTypeTheme _appTypeTheme(String appType) {
  switch (appType.toLowerCase()) {
    case 'ios':
      return const _AppTypeTheme(Color(0xFF2E9E5B), Color(0xFFE3F6EA));
    case 'both':
      return const _AppTypeTheme(Color(0xFF7C5CFC), Color(0xFFEDE8FF));
    case 'android':
    default:
      return const _AppTypeTheme(Color(0xFF4C5FEA), Color(0xFFE7E9FD));
  }
}

String _appTypeLabel(String appType) {
  switch (appType.toLowerCase()) {
    case 'ios':
      return 'iOS';
    case 'both':
      return 'Android & iOS';
    case 'android':
      return 'Android';
    default:
      return appType;
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;
  const _StatusStyle(this.label, this.color, this.background, this.icon);
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case 'in-progress':
      return const _StatusStyle('In Progress', Color(0xFFB4690E),
          Color(0xFFFCEBD5), Icons.autorenew_rounded);
    case 'dev-done':
      return const _StatusStyle('Dev Done', Color(0xFF2A5FCB),
          Color(0xFFE1E9FB), Icons.check_circle_outline_rounded);
    case 'closed':
      return const _StatusStyle('Closed', Color(0xFF2E9E5B), Color(0xFFE3F6EA),
          Icons.lock_outline_rounded);
    case 'to-do':
    default:
      return const _StatusStyle('To-do', Color(0xFF5B6472), Color(0xFFEAECF0),
          Icons.hourglass_empty_rounded);
  }
}

/// Turns an ISO-8601 timestamp into a short "2h ago" / "5d ago" style label.
String _relativeTime(String isoTimestamp) {
  final parsed = DateTime.tryParse(isoTimestamp);
  if (parsed == null) return '';
  final diff = DateTime.now().difference(parsed.toLocal());
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
  if (diff.inDays < 7) return 'Updated ${diff.inDays}d ago';
  final weeks = diff.inDays ~/ 7;
  if (weeks < 5) return 'Updated ${weeks}w ago';
  final months = diff.inDays ~/ 30;
  return 'Updated ${months}mo ago';
}

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onUpdate,
    required this.onDelete,
  });

  void _openMenu(BuildContext context, Offset position) async {
    final selection = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'update',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Update ticket'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete ticket', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );

    if (selection == 'update') {
      onUpdate();
    } else if (selection == 'delete') {
      if (!context.mounted) return;
      _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete ticket?'),
        content: Text(
          'This will permanently delete ${ticket.ticketNumber ?? 'this ticket'}. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }

  Widget _infoRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF1A1D29)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = _appTypeTheme(ticket.appType);
    final status = _statusStyle(ticket.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: appTheme.light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.groups_rounded, color: appTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketNumber ?? 'TCK-#${ticket.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF1A1D29),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 14, color: status.color),
                          const SizedBox(width: 5),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: status.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (iconContext) => IconButton(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                  onPressed: () {
                    final box = iconContext.findRenderObject() as RenderBox;
                    final position =
                        box.localToGlobal(box.size.bottomRight(Offset.zero));
                    _openMenu(context, position);
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(Icons.apartment_rounded, appTheme.primary, 'Operator',
              ticket.operatorName),
          _infoRow(Icons.language_rounded, appTheme.primary, 'Sub-domain',
              ticket.subDomain),
          _infoRow(Icons.smartphone_rounded, appTheme.primary, 'App type',
              _appTypeLabel(ticket.appType)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _relativeTime(ticket.updatedAt),
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              ElevatedButton(
                onPressed: onUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                ),
                child: const Text('Update',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
