import 'package:amap_en_ligne/data/repositories/producer_schedule_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/producer_schedule.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_screen.dart';
import 'package:amap_en_ligne/presentation/nav/back_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The basket-composition editor opened by a producer on one of its
/// deliveries (from « Mes livraisons » or its dashboard).
///
/// A producer never syncs the AMAP itself: the editor is fed with a local
/// view of it built from the producer's [ProducerSchedule] and its own
/// catalog ([producerCompositionView]), and saves through the schedule
/// ([ProducerScheduleRepository.updateBasketDescriptions]); the back writes
/// the composition back into the AMAP.
const _kProducerDeliveriesRoute = '/producer-deliveries';

class ProducerDeliveryCompositionScreen extends StatefulWidget {
  const ProducerDeliveryCompositionScreen({
    super.key,
    required this.producerAccountId,
    required this.organizationId,
    required this.deliveryId,
  });

  final String producerAccountId;
  final String organizationId;
  final String deliveryId;

  @override
  State<ProducerDeliveryCompositionScreen> createState() =>
      _ProducerDeliveryCompositionScreenState();
}

class _ProducerDeliveryCompositionScreenState
    extends State<ProducerDeliveryCompositionScreen> {
  late final Future<(ProducerSchedule?, List<ProductType>)> _load = _loadData();

  Future<(ProducerSchedule?, List<ProductType>)> _loadData() async {
    final scheduleRepository = context.read<ProducerScheduleRepository>();
    final productTypeRepository = context.read<ProductTypeRepository>();
    final schedules = await scheduleRepository
        .watch(widget.producerAccountId)
        .first;
    final productTypes = await productTypeRepository
        .watch(widget.producerAccountId)
        .first;
    final schedule = schedules
        .where((s) => s.organizationId == widget.organizationId)
        .firstOrNull;
    return (schedule, productTypes);
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(ProducerSchedule?, List<ProductType>)>(
        future: _load,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => popOrGo(context, _kProducerDeliveriesRoute),
                ),
                title: const Text('Composition du panier'),
              ),
              body: Center(
                child: snapshot.hasError
                    ? const Text('Livraison introuvable.')
                    : const CircularProgressIndicator(),
              ),
            );
          }
          final (schedule, productTypes) = data;
          final organization = schedule == null
              ? null
              : producerCompositionView(
                  schedule,
                  widget.deliveryId,
                  productTypes,
                );
          if (schedule == null || organization == null) {
            return Scaffold(
              appBar: AppBar(
                leading: BackButton(
                  onPressed: () => popOrGo(context, _kProducerDeliveriesRoute),
                ),
                title: const Text('Composition du panier'),
              ),
              body: const Center(child: Text('Livraison introuvable.')),
            );
          }
          final repository = context.read<ProducerScheduleRepository>();
          return DeliveryDescriptionScreen(
            org: organization,
            deliveryId: widget.deliveryId,
            backRoute: _kProducerDeliveriesRoute,
            // The component icons are resolved by the back from the
            // producer's catalog: only the compositions travel.
            save:
                ({
                  required org,
                  required delivery,
                  required descriptions,
                  required itemTypes,
                }) => repository.updateBasketDescriptions(
                  schedule: schedule,
                  deliveryId: delivery.deliveryId,
                  basketDescriptions: descriptions,
                ),
          );
        },
      );
}

/// The AMAP as the composition editor needs it, seen by the producer: its
/// [deliveryId] from [schedule] and, as products, the producer's own
/// [productTypes] — restricted to the products and basket sizes the delivery
/// carries (the AMAP may offer fewer than the producer's catalog; the back
/// rejects the others). A legacy delivery without any description offers
/// every product of the catalog. Null when the delivery is not in [schedule].
Organization? producerCompositionView(
  ProducerSchedule schedule,
  String deliveryId,
  List<ProductType> productTypes,
) {
  final delivery = schedule.deliveries
      .where((d) => d.deliveryId == deliveryId)
      .firstOrNull;
  if (delivery == null) return null;
  final sizesByProduct = <String, List<String>>{};
  for (final description in delivery.basketDescriptions) {
    sizesByProduct
        .putIfAbsent(description.productTypeId, () => [])
        .add(description.basketSizeName);
  }
  final products = [
    for (final productType in productTypes)
      if (sizesByProduct.isEmpty ||
          sizesByProduct.containsKey(productType.productTypeId))
        OrgProduct(
          name: productType.name,
          productTypeId: productType.productTypeId,
          producerAccountId: productType.producerAccountId,
          supportedBasketSizes: [
            for (final name
                in sizesByProduct[productType.productTypeId] ??
                    productType.supportedBasketSizes.map((s) => s.name))
              BasketSize(name: name),
          ],
        ),
  ];
  return Organization(
    organizationId: schedule.organizationId,
    name: schedule.organizationName,
    contactEmail: '',
    products: products,
    deliveries: [
      Delivery(
        deliveryId: delivery.deliveryId,
        organizationId: schedule.organizationId,
        scheduledDate: delivery.scheduledDate,
        status: delivery.status,
        minVolunteersRequired: 0,
        basketDescriptions: delivery.basketDescriptions,
      ),
    ],
  );
}
