import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/ticket_card.dart';
import '../ticket/update_ticket_screen.dart';

class DashboardTab extends ConsumerStatefulWidget {
  /// Called when the person taps the avatar in the header - the parent
  /// HomeScreen uses this to switch the bottom nav to the Profile tab.
  final VoidCallback? onProfileTap;

  const DashboardTab({super.key, this.onProfileTap});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    final userId = ref.read(authProvider).user?.id;
    if (userId != null) {
      ref.read(ticketListProvider.notifier).fetchMyTickets(userId);
    }
  }

  Future<void> _openUpdateScreen(Ticket ticket) async {
    final refreshed = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UpdateTicketScreen(ticket: ticket)),
    );
    if (refreshed == true) _refresh();
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    final success =
        await ref.read(ticketListProvider.notifier).deleteTicket(ticket);
    if (!mounted) return;
    final message = success
        ? '${ticket.ticketNumber ?? 'Ticket'} deleted'
        : ref.read(ticketListProvider).error ?? 'Could not delete ticket';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts[0][0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  Widget _header() {
    final user = ref.watch(authProvider).user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Welcome back! Here's your team overview.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onProfileTap,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _initials(user?.name),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketListProvider);

    return Column(
      children: [
        _header(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: Builder(
              builder: (context) {
                if (state.isLoading && state.tickets.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null && state.tickets.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(state.error!)),
                    ],
                  );
                }
                if (state.tickets.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(
                          child: Text('No tickets yet. Tap + to create one.')),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 90),
                  itemCount: state.tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = state.tickets[index];
                    return TicketCard(
                      ticket: ticket,
                      onUpdate: () => _openUpdateScreen(ticket),
                      onDelete: () => _deleteTicket(ticket),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
