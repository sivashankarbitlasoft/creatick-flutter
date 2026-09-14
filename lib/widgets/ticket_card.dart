import 'package:flutter/material.dart';

import '../models/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onUpdate;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onUpdate,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'to-do':
        return Colors.grey;
      case 'in-progress':
        return Colors.orange;
      case 'dev-done':
        return Colors.blue;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.ticketNumber ?? 'TCK-#${ticket.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  label: Text(
                    ticket.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _statusColor(ticket.status),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Operator: ${ticket.operatorName}'),
            Text('Sub-domain: ${ticket.subDomain}'),
            Text('App type: ${ticket.appType}'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onUpdate,
                child: const Text('Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
