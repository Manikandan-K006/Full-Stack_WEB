import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/app_dialogs.dart';
import '../models/listing.dart';
import '../services/classified_service.dart';

class ListingFormDialog extends StatefulWidget {
  final Listing? initial;
  const ListingFormDialog({super.key, this.initial});

  @override
  State<ListingFormDialog> createState() => _ListingFormDialogState();
}

class _ListingFormDialogState extends State<ListingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _location;
  late final List<TextEditingController> _imageControllers;
  late String _category;
  late String _condition;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _price = TextEditingController(
        text: initial == null ? '' : initial.price.toString());
    _location = TextEditingController(text: initial?.location ?? '');
    _imageControllers = [
      for (final image in initial?.images ?? const <String>[])
        TextEditingController(text: image),
    ];
    if (_imageControllers.isEmpty) _imageControllers.add(TextEditingController());
    _category = initial?.category ?? Listing.categories.first;
    _condition = initial?.condition ?? 'GOOD';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    for (final c in _imageControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addImageField() {
    if (_imageControllers.length >= 6) return;
    setState(() => _imageControllers.add(TextEditingController()));
  }

  void _removeImageField(int index) {
    setState(() {
      _imageControllers.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final images = [
        for (final c in _imageControllers)
          if (c.text.trim().isNotEmpty) c.text.trim(),
      ];
      if (_isEdit) {
        await ClassifiedService.updateListing(widget.initial!.id, {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'price': double.tryParse(_price.text.trim()) ?? 0,
          'category': _category,
          'condition': _condition,
          'location': _location.text.trim(),
          'images': images,
        });
      } else {
        await ClassifiedService.createListing(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: double.tryParse(_price.text.trim()) ?? 0,
          category: _category,
          condition: _condition,
          location: _location.text.trim(),
          images: images,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Listing' : 'Sell an Item'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      Validators.required(v, 'Title') ?? Validators.minLength(v, 3, 'Title'),
                ),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  maxLength: 3000,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => Validators.required(v, 'Description') ??
                      Validators.minLength(v, 10, 'Description'),
                ),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price (₹)'),
                  validator: (v) => Validators.positiveNumber(v, 'Price'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: [
                          for (final c in Listing.categories)
                            DropdownMenuItem(value: c, child: Text(Formatters.enumLabel(c))),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _condition,
                        decoration: const InputDecoration(labelText: 'Condition'),
                        items: [
                          for (final c in Listing.conditions)
                            DropdownMenuItem(value: c, child: Text(Formatters.enumLabel(c))),
                        ],
                        onChanged: (v) => setState(() => _condition = v ?? _condition),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (v) =>
                      Validators.required(v, 'Location') ?? Validators.minLength(v, 2, 'Location'),
                ),
                const SizedBox(height: 4),
                const Text('Images (up to 6)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (var i = 0; i < _imageControllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageControllers[i],
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: 'Image URL ${i + 1}',
                              hintText: 'https://example.com/photo.jpg',
                            ),
                            validator: (v) => Validators.url(v, 'Image URL'),
                          ),
                        ),
                        if (_imageControllers.length > 1)
                          IconButton(
                            tooltip: 'Remove image',
                            onPressed: () => _removeImageField(i),
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                  ),
                if (_imageControllers.length < 6)
                  TextButton.icon(
                    onPressed: _addImageField,
                    icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    label: const Text('Add image'),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.classifieds),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? 'Save changes' : 'Create listing'),
        ),
      ],
    );
  }
}