import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_button.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductTypesScreen extends StatelessWidget {
  const ProductTypesScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProductTypeRepository>();
    final isAuthenticated = context.select(
      (AuthBloc bloc) => bloc.state.producerId != null,
    );
    if (!isAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return ConnectedScaffold(
      title: 'Types de produits',
      actions: const [SyncButton()],
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: StreamBuilder<List<ProductType>>(
              stream: repo.watch(tenantId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('Aucun type de produit.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final pt = items[i];
                    return Dismissible(
                      key: ValueKey(pt.productTypeId),
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await repo.delete(
                          tenantId: tenantId,
                          productTypeId: pt.productTypeId,
                        );
                        if (context.mounted) {
                          context.read<SyncBloc>().add(
                            const SyncEvent.mutationApplied(),
                          );
                        }
                      },
                      child: ListTile(
                        title: Text(pt.name),
                        subtitle: pt.description == null
                            ? null
                            : Text(pt.description!),
                        trailing: Text(
                          '${pt.supportedBasketSizes.length} sizes',
                        ),
                        onTap: () =>
                            context.push('/product-types/${pt.productTypeId}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/product-types/new'),
        tooltip: 'Ajouter un type de produit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
