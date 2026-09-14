import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_service.dart';
import '../core/api_exception.dart';
import '../models/ticket_model.dart';

class TicketListState {
  final List<Ticket> tickets;
  final bool isLoading;
  final String? error;

  const TicketListState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  TicketListState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return TicketListState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TicketListNotifier extends StateNotifier<TicketListState> {
  TicketListNotifier() : super(const TicketListState());

  Future<void> fetchMyTickets(int userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tickets = await ApiService.getMyTickets(userId);
      state = state.copyWith(tickets: tickets, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not reach the server. Check your connection.',
      );
    }
  }

  /// Returns true on success so the create-ticket screen knows to clear
  /// its form and show a success message.
  Future<bool> createTicket({
    required String operatorName,
    required String subDomain,
    String? website,
    String? description,
    required List<String?> imageUrls,
    required String appType,
    required int createdBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newTickets = await ApiService.createTicket(
        operatorName: operatorName,
        subDomain: subDomain,
        website: website,
        description: description,
        imageUrls: imageUrls,
        appType: appType,
        createdBy: createdBy,
      );
      // Put the newly created ticket(s) at the top of the list right away.
      state = state.copyWith(
        tickets: [...newTickets, ...state.tickets],
        isLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not reach the server. Check your connection.',
      );
      return false;
    }
  }

  Future<bool> deleteTicket(Ticket ticket) async {
    final ticketNumber = ticket.ticketNumber;
    if (ticketNumber == null) return false;
    final previousTickets = state.tickets;
    state = state.copyWith(
      tickets: previousTickets.where((t) => t.id != ticket.id).toList(),
    );
    try {
      await ApiService.deleteTicket(ticketNumber);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(tickets: previousTickets, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        tickets: previousTickets,
        error: 'Could not reach the server. Check your connection.',
      );
      return false;
    }
  }
}

final ticketListProvider =
    StateNotifierProvider<TicketListNotifier, TicketListState>((ref) {
  return TicketListNotifier();
});
