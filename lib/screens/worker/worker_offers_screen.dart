import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/offers_provider.dart';
import 'package:go_router/go_router.dart';

class WorkerOffersScreen extends StatefulWidget {
  const WorkerOffersScreen({super.key});

  @override
  State<WorkerOffersScreen> createState() => _WorkerOffersScreenState();
}

class _WorkerOffersScreenState extends State<WorkerOffersScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<OffersProvider>(context, listen: false);
    Future.microtask(() {
      provider.fetchWorkerOffers();
      provider.startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final offersProvider = context.watch<OffersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ofertas')),
      body:
          offersProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : offersProvider.error != null
              ? Center(child: Text(offersProvider.error!))
              : RefreshIndicator(
                onRefresh: () => offersProvider.fetchWorkerOffers(),
                child: ListView.builder(
                  itemCount: offersProvider.offers.length,
                  itemBuilder: (context, index) {
                    final offer = offersProvider.offers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(offer['jobTitle'] ?? 'Trabajo'),
                        subtitle: Text(
                          'Presupuesto: S/ ${offer['proposedBudget']?.toStringAsFixed(0) ?? '-'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectOffer(context, offer),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () => _acceptOffer(context, offer),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  @override
  void dispose() {
    Provider.of<OffersProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  Future<void> _acceptOffer(
    BuildContext context,
    Map<String, dynamic> offer,
  ) async {
    final provider = context.read<OffersProvider>();
    final ok = await provider.acceptOffer(offer['id']);
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oferta aceptada')));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        context.go('/worker/chats');
      }
    }
  }

  Future<void> _rejectOffer(
    BuildContext context,
    Map<String, dynamic> offer,
  ) async {
    final provider = context.read<OffersProvider>();
    final ok = await provider.rejectOffer(offer['id']);
    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Oferta rechazada')));
    }
  }
}
