// Copyright 2025 The Flutter Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dart_schema_builder/dart_schema_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

import 'package:intl/intl.dart';

import '../tools/booking/booking_service.dart';
import '../tools/booking/model.dart';

final _schema = S.object(
  description: 'A widget to check out set of listings.',
  properties: {
    'listingSelectionIds': S.list(
      description: 'Listings to checkout.',
      items: S.string(),
    ),
    'itineraryName': S.string(description: 'The name of the itinerary.'),
  },
  required: ['listingSelectionIds'],
);

extension type _ListingsBookerData.fromMap(Map<String, Object?> _json) {
  factory _ListingsBookerData({
    required List<String> listingSelectionIds,
    required String itineraryName,
  }) => _ListingsBookerData.fromMap({
    'listingSelectionIds': listingSelectionIds,
    'itineraryName': itineraryName,
  });

  List<String> get listingSelectionIds =>
      (_json['listingSelectionIds'] as List).cast<String>();
  String get itineraryName => _json['itineraryName'] as String;
}

final listingsBooker = CatalogItem(
  name: 'ListingsBooker',
  dataSchema: _schema,
  widgetBuilder:
      ({
        required data,
        required id,
        required buildChild,
        required dispatchEvent,
        required context,
        required values,
      }) {
        final listingsBookerData = _ListingsBookerData.fromMap(
          data as Map<String, Object?>,
        );
        return _ListingsBooker(
          listingSelectionIds: listingsBookerData.listingSelectionIds,
          itineraryName: listingsBookerData.itineraryName,
          dispatchEvent: dispatchEvent,
          widgetId: id,
        );
      },
  exampleData: [
    () {
      final start1 = DateTime.now().add(const Duration(days: 5));
      final end1 = start1.add(const Duration(days: 2));
      final start2 = end1.add(const Duration(days: 1));
      final end2 = start2.add(const Duration(days: 2));

      final listingSelectionId1 = BookingService.instance
          .listHotelsSync(
            HotelSearch(query: '', checkIn: start1, checkOut: end1, guests: 1),
          )
          .listings
          .first
          .listingSelectionId;
      final listingSelectionId2 = BookingService.instance
          .listHotelsSync(
            HotelSearch(query: '', checkIn: start2, checkOut: end2, guests: 1),
          )
          .listings
          .last
          .listingSelectionId;

      return {
        'root': 'listings_booker',
        'widgets': [
          {
            'id': 'listings_booker',
            'widget': {
              'ListingsBooker': {
                'listingSelectionIds': [
                  listingSelectionId1,
                  listingSelectionId2,
                ],
                'itineraryName': 'Dart and Flutter deep dive',
              },
            },
          },
        ],
      };
    },
  ],
);

enum BookingStatus { initial, inProgress, done }

class CreditCard {
  final String cardholderName;
  final String cardNumber;
  final String expiryDate;
  final String paymentMethodId;

  CreditCard({
    required this.cardholderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.paymentMethodId,
  });
}

class _ListingsBooker extends StatefulWidget {
  final List<String> listingSelectionIds;
  final String itineraryName;
  final DispatchEventCallback dispatchEvent;
  final String widgetId;

  const _ListingsBooker({
    required this.listingSelectionIds,
    required this.itineraryName,
    required this.dispatchEvent,
    required this.widgetId,
  });

  @override
  State<_ListingsBooker> createState() => _ListingsBookerState();
}

class _CustomRadio<T> extends StatefulWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const _CustomRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  State<_CustomRadio<T>> createState() => _CustomRadioState<T>();
}

class _CustomRadioState<T> extends State<_CustomRadio<T>> {
  @override
  Widget build(BuildContext context) {
    final isSelected = widget.value == widget.groupValue;
    return InkWell(
      onTap: () {
        if (widget.onChanged != null) {
          widget.onChanged!(widget.value);
        }
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 2,
          ),
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _ListingsBookerState extends State<_ListingsBooker> {
  BookingStatus _bookingStatus = BookingStatus.initial;
  CreditCard? _selectedCard;
  late final List<HotelListing> _selections;

  @override
  void initState() {
    super.initState();
    _selections = widget.listingSelectionIds
        .map((id) => BookingService.instance.listings[id])
        .whereType<HotelListing>()
        .toList();
  }

  final _creditCards = [
    CreditCard(
      cardholderName: 'John Doe',
      cardNumber: '**** **** **** 1234',
      expiryDate: '12/25',
      paymentMethodId: 'pm_1',
    ),
    CreditCard(
      cardholderName: 'Jane Doe',
      cardNumber: '**** **** **** 5678',
      expiryDate: '08/26',
      paymentMethodId: 'pm_2',
    ),
  ];

  Future<void> _book() async {
    setState(() {
      _bookingStatus = BookingStatus.inProgress;
    });
    await BookingService.instance.bookSelections(
      _selections.map((e) => e.listingSelectionId).toList(),
      _selectedCard!.paymentMethodId,
    );
    if (mounted) {
      setState(() {
        _bookingStatus = BookingStatus.done;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = _selections.fold<double>(0.0, (sum, listing) {
      final duration = listing.search.checkOut.difference(
        listing.search.checkIn,
      );
      return sum + (duration.inDays * listing.pricePerNight);
    });

    const spacing = 10.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Check out "${widget.itineraryName}"',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selections.length,
          itemBuilder: (context, index) {
            final listing = _selections[index];
            final checkIn = listing.search.checkIn;
            final checkOut = listing.search.checkOut;
            final duration = checkOut.difference(checkIn);
            final totalPrice = duration.inDays * listing.pricePerNight;
            final dateFormat = DateFormat.yMMMd();

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.asset(
                            listing.images.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                listing.location,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selections.remove(listing);
                                });
                              },
                              child: const Text('Remove'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                widget.dispatchEvent(
                                  UiActionEvent(
                                    eventType: 'Modify',
                                    widgetId: widget.widgetId,
                                    value: {
                                      'listingSelectionId':
                                          listing.listingSelectionId,
                                    },
                                  ),
                                );
                              },
                              child: const Text('Modify'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: spacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              dateFormat.format(checkIn),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Check-out',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              dateFormat.format(checkOut),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: spacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration of stay:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${duration.inDays} nights',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: spacing / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total price:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total:',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '\$${grandTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: spacing),
              Text(
                'Select Payment Method',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: spacing),
              Column(
                children: _creditCards.map((card) {
                  return ListTile(
                    leading: _CustomRadio<CreditCard>(
                      value: card,
                      groupValue: _selectedCard,
                      onChanged: (value) {
                        setState(() {
                          _selectedCard = value;
                        });
                      },
                    ),
                    title: Text(card.cardholderName),
                    subtitle: Text(
                      '${card.cardNumber}\nExpires: ${card.expiryDate}',
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: spacing * 2),
              _BookButton(
                bookingStatus: _bookingStatus,
                selectedCard: _selectedCard,
                onPressed: _book,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final BookingStatus bookingStatus;
  final CreditCard? selectedCard;
  final VoidCallback? onPressed;

  const _BookButton({
    required this.bookingStatus,
    required this.selectedCard,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _SubmitButton(
        onPressed:
            selectedCard != null && bookingStatus == BookingStatus.initial
            ? onPressed
            : null,
        child: switch (bookingStatus) {
          BookingStatus.initial => const Text('Book'),
          BookingStatus.inProgress => const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          BookingStatus.done => const Icon(Icons.check, size: 24),
        },
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: child,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
