import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/loading_widget.dart';
import '../models/address.dart';
import '../services/food_service.dart';
import '../widgets/page_header.dart';

const List<String> _addressLabels = ['Home', 'Work', 'Other'];

Future<DeliveryAddress?> showAddressDialog(
  BuildContext context, {
  DeliveryAddress? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  var label = existing?.label ?? 'Home';
  final fullName = TextEditingController(text: existing?.fullName ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final addressLine =
      TextEditingController(text: existing?.addressLine ?? '');
  final city = TextEditingController(text: existing?.city ?? '');
  final state = TextEditingController(text: existing?.state ?? '');
  final postalCode = TextEditingController(text: existing?.postalCode ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Add address' : 'Edit address',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: label,
                decoration: const InputDecoration(labelText: 'Label'),
                items: [
                  for (final l in _addressLabels)
                    DropdownMenuItem(value: l, child: Text(l)),
                ],
                onChanged: (value) {
                  if (value != null) label = value;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fullName,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => Validators.required(v, 'Full name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressLine,
                decoration: const InputDecoration(labelText: 'Address line'),
                validator: (v) => Validators.required(v, 'Address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: city,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => Validators.required(v, 'City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: state,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (v) => Validators.required(v, 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: postalCode,
                decoration: const InputDecoration(labelText: 'Postal code'),
                validator: (v) => Validators.required(v, 'Postal code'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.food),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  final controllers = [fullName, phone, addressLine, city, state, postalCode];
  final result = saved == true
      ? DeliveryAddress(
          id: existing?.id ?? '',
          label: label,
          fullName: fullName.text.trim(),
          phone: phone.text.trim(),
          addressLine: addressLine.text.trim(),
          city: city.text.trim(),
          state: state.text.trim(),
          postalCode: postalCode.text.trim(),
        )
      : null;
  for (final c in controllers) {
    c.dispose();
  }
  return result;
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final FoodService _service = FoodService();

  bool _loading = true;
  String? _error;
  List<DeliveryAddress> _addresses = [];

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
      final addresses = await _service.listAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
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

  Future<void> _addAddress() async {
    final address = await showAddressDialog(context);
    if (address == null || !mounted) return;
    try {
      await _service.addAddress(
        label: address.label,
        fullName: address.fullName,
        phone: address.phone,
        addressLine: address.addressLine,
        city: address.city,
        state: address.state,
        postalCode: address.postalCode,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Address saved');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _deleteAddress(DeliveryAddress address) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete address?',
      message:
          'Delete "${address.label}" at ${address.addressLine}? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.deleteAddress(address.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Address deleted');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: 'My Addresses',
          subtitle: '${_addresses.length} saved',
          actions: [
            IconButton(
              onPressed: _addAddress,
              icon: const Icon(Icons.add_rounded, color: ExperimentPalette.food),
              tooltip: 'Add address',
            ),
          ],
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading addresses…')
              : _error != null
                  ? ErrorWidgetView(message: _error!, onRetry: _load)
                  : _addresses.isEmpty
                      ? EmptyState(
                          icon: Icons.location_off_rounded,
                          title: 'No saved addresses',
                          subtitle: 'Add a delivery address to check out faster',
                          action: OutlinedButton.icon(
                            onPressed: _addAddress,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add address'),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            for (final address in _addresses)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AnimatedCard(
                                  accentColor: ExperimentPalette.food,
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: ExperimentPalette.food
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                            Icons.location_on_rounded,
                                            color: ExperimentPalette.food,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: ExperimentPalette.food
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    address.label,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: ExperimentPalette
                                                            .food),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    address.fullName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            AppColors.textDark),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              address.summary,
                                              style: TextStyle(
                                                  fontSize: 12.5,
                                                  color: Colors.grey.shade700),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${address.state} • ${address.postalCode} • ${address.phone}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _deleteAddress(address),
                                        icon: const Icon(
                                            Icons.delete_outline_rounded),
                                        color: AppColors.danger,
                                        tooltip: 'Delete address',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }
}
