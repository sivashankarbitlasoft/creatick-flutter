import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/ticket_card.dart';
import '../ticket/update_ticket_screen.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // Runs after the first frame so `ref` is safe to use.
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketListProvider);

    return RefreshIndicator(
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
                Center(child: Text('No tickets yet. Tap + to create one.')),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: state.tickets.length,
            itemBuilder: (context, index) {
              final ticket = state.tickets[index];
              return TicketCard(
                ticket: ticket,
                onUpdate: () => _openUpdateScreen(ticket),
              );
            },
          );
        },
      ),
    );
  }
}
