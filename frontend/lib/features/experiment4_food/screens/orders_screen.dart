import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_chip.dart';
import '../models/order.dart';
import '../services/food_service.dart';
import '../widgets/page_header.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FoodService _service = FoodService();

  bool _loading = true;
  String? _error;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service.listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppDialogs.friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'My Orders',
          subtitle: '${_orders.length} order${_orders.length == 1 ? '' : 's'}',
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading orders…')
              : _error != null
                  ? ErrorWidgetView(message: _error!, onRetry: _load)
                  : _orders.isEmpty
                      ? const EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No orders yet',
                          subtitle:
                              'Orders you place will appear here with live status',
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            for (final order in _orders)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _OrderCard(order: order),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accentColor: ExperimentPalette.food,
      padding: EdgeInsets.zero,
      radius: const BorderRadius.all(Radius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: const Border(),
        iconColor: ExperimentPalette.food,
        collapsedIconColor: AppColors.textMuted,
        title: Row(
          children: [
            Expanded(
              child: Text(
                order.restaurantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(status: order.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.dateTime(order.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Formatters.currency(order.total, exact: true),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: ExperimentPalette.food),
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 14),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} × ${item.quantity}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textDark),
                    ),
                  ),
                  Text(
                    Formatters.currency(item.subtotal, exact: true),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Divider(height: 10),
          _DetailRow(
              label: 'Subtotal',
              value: Formatters.currency(order.subtotal, exact: true)),
          _DetailRow(
              label: 'Delivery fee',
              value: Formatters.currency(order.deliveryFee, exact: true)),
          _DetailRow(
              label: 'Total',
              value: Formatters.currency(order.total, exact: true),
              bold: true),
          const SizedBox(height: 10),
          _DetailRow(
              label: 'Payment',
              value: Formatters.enumLabel(order.paymentMethod)),
          const SizedBox(height: 6),
          _DetailRow(
            label: 'Deliver to',
            value: order.address.summary,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          const Text('Status history',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          for (final event in order.statusHistory)
            _HistoryRow(event: event),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final int maxLines;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? AppColors.textDark : AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final StatusHistoryEvent event;

  const _HistoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = StatusChip.colorFor(event.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(status: event.status),
                    const Spacer(),
                    Text(
                      Formatters.dateTime(event.at),
                      style:
                          TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (event.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.note,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
