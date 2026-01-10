import 'package:campus_event/models/registration_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/registration_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Event'),
        actions: [
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              return IconButton(
                icon: Icon(
                  _event.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _event.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  eventProvider.toggleFavorite(_event.id);
                  setState(() {
                    _event = _event.copyWith(isFavorite: !_event.isFavorite);
                  });
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.image, size: 100, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(label: Text(_event.category)),
                      const Spacer(),
                      Text(
                        '${_event.registered}/${_event.capacity} peserta',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    title: 'Tanggal & Waktu',
                    value: _formatDateTime(_event.dateTime),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    title: 'Lokasi',
                    value: _event.location,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.person,
                    title: 'Pembicara',
                    value: _event.speaker,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.phone,
                    title: 'Kontak',
                    value: _event.contact,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.business,
                    title: 'Penyelenggara',
                    value: _event.organizer,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kapasitas Pendaftaran',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _event.capacityPercentage,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_event.capacityPercentage * 100).toStringAsFixed(1)}% Terpenuhi',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Deskripsi',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _event.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer2<AuthProvider, RegistrationProvider>(
          builder: (context, authProvider, regProvider, _) {
            final userId = authProvider.currentUser?.id ?? '';

            if (userId.isEmpty) {
              return ElevatedButton(
                onPressed: null,
                child: const Text('Login terlebih dahulu'),
              );
            }

            return FutureBuilder<bool>(
              future: regProvider.isUserRegistered(userId, _event.id),
              builder: (context, snapshot) {
                final isRegistered = snapshot.data ?? false;

                return ElevatedButton(
                  onPressed:
                      (_event.isFull && !isRegistered)
                          ? null
                          : () async {
                            if (isRegistered) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Batalkan Pendaftaran'),
                                  content: const Text(
                                    'Apakah Anda yakin ingin membatalkan pendaftaran?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Tidak'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Ya'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                try {
                                  final registrations = 
                                      await regProvider.getUserRegistrations(userId);
                                  
                                  // Cari registration untuk event ini
                                  Registration? reg;
                                  try {
                                    reg = registrations.firstWhere(
                                      (r) => r.eventId == _event.id,
                                    );
                                  } catch (e) {
                                    reg = null;
                                  }

                                  if (reg != null && context.mounted) {
                                    await regProvider.cancelRegistration(
                                      reg.id,
                                      userId,
                                    );
                                    setState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Pendaftaran dibatalkan'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Registrasi tidak ditemukan'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            } else {
                              final success =
                                  await regProvider.registerEvent(userId, _event.id);
                              if (success && context.mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Berhasil didaftarkan!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      regProvider.errorMessage ??
                                          'Gagal mendaftar',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRegistered ? Colors.orange : Colors.red,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    isRegistered ? 'Batalkan Pendaftaran' : 'Daftar Sekarang',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(dateTime);
  }
}