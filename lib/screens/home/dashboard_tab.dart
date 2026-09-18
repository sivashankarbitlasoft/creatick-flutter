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
  bool _showFilters = false;
  String _searchText = '';

  // normalized status keys: 'todo','inprogress','devdone','closed','reopen'
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedSubDomains = {};
  final Set<String> _selectedAppTypes = {};
  DateTimeRange? _customRange;
  bool _todaySelected = false;

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

  // normalize status strings to simple keys for comparison
  String _normalizeStatusKey(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), '');
  }

  String _normalizeFilterValue(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r"[^a-z0-9]"), '');
  }

  String _formatAppType(String appType) {
    switch (appType.trim().toLowerCase()) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'both':
        return 'Both';
      default:
        return appType.trim().isEmpty ? 'Unknown' : appType.trim();
    }
  }

  Future<void> _openMultiSelectDialog({
    required String title,
    required List<String> options,
    required Set<String> selected,
    required void Function(Set<String>) onApply,
  }) async {
    final current = Set<String>.from(selected);
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: options.map((value) {
                  final key = _normalizeFilterValue(value);
                  final isSelected = current.contains(key);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(value),
                    onChanged: (v) {
                      setDialogState(() {
                        if (v == true) {
                          current.add(key);
                        } else {
                          current.remove(key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onApply(Set<String>.from(current));
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _todaySelected = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatuses.clear();
      _selectedSubDomains.clear();
      _selectedAppTypes.clear();
      _customRange = null;
      _todaySelected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketListProvider);

    final subdomains = state.tickets
        .map((t) => t.subDomain)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final statusLabels = state.tickets
        .map((t) => t.status)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final appTypes = state.tickets
        .map((t) => _formatAppType(t.appType))
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    List<Ticket> filtered = List.from(state.tickets);

    if (_searchText.trim().isNotEmpty) {
      final query = _searchText.trim().toLowerCase();
      filtered = filtered.where((ticket) {
        final haystack = [
          ticket.ticketNumber ?? '',
          ticket.operatorName,
          ticket.subDomain,
          ticket.appType,
          ticket.status,
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((t) {
        final key = _normalizeStatusKey(t.status);
        return _selectedStatuses.contains(key);
      }).toList();
    }

    if (_selectedSubDomains.isNotEmpty) {
      filtered = filtered
          .where((t) => _selectedSubDomains.contains(_normalizeFilterValue(t.subDomain)))
          .toList();
    }

    if (_selectedAppTypes.isNotEmpty) {
      filtered = filtered
          .where((t) => _selectedAppTypes.contains(_normalizeFilterValue(t.appType)))
          .toList();
    }


    if (_todaySelected) {
      final today = DateTime.now();
      filtered = filtered.where((t) {
        final parsed = DateTime.tryParse(t.createdAt);
        if (parsed == null) return false;
        final d = parsed.toLocal();
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();
    } else if (_customRange != null) {
      filtered = filtered.where((t) {
        final parsed = DateTime.tryParse(t.createdAt);
        if (parsed == null) return false;
        final d = parsed.toLocal();
        final start = _customRange!.start;
        final end = _customRange!.end;
        return (!d.isBefore(start) && !d.isAfter(end)) ||
            (d.isAtSameMomentAs(start) || d.isAtSameMomentAs(end));
      }).toList();
    }

    final filterWidth = (MediaQuery.of(context).size.width - 64) / 2;

    return Column(
      children: [
        _header(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                    hintText: 'Search...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => setState(() => _showFilters = !_showFilters),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, color: Color(0xFF4C5FEA)),
                      const SizedBox(width: 6),
                      const Text('Filter', style: TextStyle(color: Color(0xFF4C5FEA))),
                      const SizedBox(width: 6),
                      Icon(
                        _showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF4C5FEA),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showFilters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filter by', style: TextStyle(fontWeight: FontWeight.w600)),
                        TextButton(onPressed: _clearFilters, child: const Text('Clear')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: (filterWidth / 60),
                      children: [
                        _filterTile(
                          width: filterWidth,
                          label: 'Status',
                          value: _selectedStatuses.isEmpty
                              ? 'All'
                              : '${_selectedStatuses.length} selected',
                          onTap: () => _openMultiSelectDialog(
                            title: 'Select statuses',
                            options: statusLabels,
                            selected: _selectedStatuses,
                            onApply: (value) => setState(() { 
                              _selectedStatuses
                                ..clear()
                                ..addAll(value);
                            }),
                          ),
                        ),
                        _filterTile(
                          width: filterWidth,
                          label: 'Date',
                          value: _todaySelected
                              ? 'Today'
                              : (_customRange != null
                                  ? '${_customRange!.start.day}/${_customRange!.start.month} - ${_customRange!.end.day}/${_customRange!.end.month}'
                                  : 'All'),
                          onTap: () async {
                            final choice = await showModalBottomSheet<String?>(
                              context: context,
                              builder: (dialogContext) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: const Text('Today'),
                                      onTap: () => Navigator.of(dialogContext).pop('today'),
                                    ),
                                    ListTile(
                                      title: const Text('Custom range'),
                                      onTap: () => Navigator.of(dialogContext).pop('custom'),
                                    ),
                                    ListTile(
                                      title: const Text('All dates'),
                                      onTap: () => Navigator.of(dialogContext).pop('clear'),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (choice == 'today') {
                              setState(() {
                                _todaySelected = true;
                                _customRange = null;
                              });
                            } else if (choice == 'custom') {
                              await _pickCustomRange();
                            } else if (choice == 'clear') {
                              setState(() {
                                _todaySelected = false;
                                _customRange = null;
                              });
                            }
                          },
                        ),
                        _filterTile(
                          width: filterWidth,
                          label: 'Sub-domain',
                          value: _selectedSubDomains.isEmpty
                              ? 'All'
                              : '${_selectedSubDomains.length} selected',
                          onTap: () => _openMultiSelectDialog(
                            title: 'Select sub-domains',
                            options: subdomains,
                            selected: _selectedSubDomains,
                            onApply: (value) => setState(() {
                              _selectedSubDomains
                                ..clear()
                                ..addAll(value);
                            }),
                          ),
                        ),
                        _filterTile(
                          width: filterWidth,
                          label: 'App Type',
                          value: _selectedAppTypes.isEmpty
                              ? 'All'
                              : '${_selectedAppTypes.length} selected',
                          onTap: () => _openMultiSelectDialog(
                            title: 'Select app types',
                            options: appTypes,
                            selected: _selectedAppTypes,
                            onApply: (value) => setState(() {
                              _selectedAppTypes
                                ..clear()
                                ..addAll(value);
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                if (filtered.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No tickets match the current filters.')),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 90),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
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

  Widget _filterTile({
    required double width,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF4C5FEA))),
          ],
        ),
      ),
    );
  }
}
