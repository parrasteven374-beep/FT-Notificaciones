import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/item.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import 'new_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _eventAdvance = Duration(minutes: 15);

  final _service = NotificationService.instance;
  final _items = <Item>[];
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPermission());
  }

  Future<void> _askPermission() async {
    final granted = await _service.requestPermission();
    if (!mounted) return;
    setState(() => _granted = granted);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _create(ItemType type) async {
    final item = await Navigator.push<Item>(
      context,
      MaterialPageRoute(builder: (_) => NewItemScreen(type: type)),
    );
    if (item == null) return;
    await _scheduleItem(item);
    setState(() {
      _items.add(item);
      _items.sort((a, b) => a.when.compareTo(b.when));
    });
    _snack('Guardado');
  }

  Future<void> _scheduleItem(Item item) {
    var notifyAt = item.when;
    var title = 'Recordatorio';
    var body = item.title;

    if (item.type == ItemType.tarea) {
      title = 'Tarea pendiente';
    } else if (item.type == ItemType.evento) {
      title = 'Evento en 15 minutos';
      final early = item.when.subtract(_eventAdvance);
      if (early.isAfter(DateTime.now())) {
        notifyAt = early;
      } else {
        title = 'Evento ahora';
      }
    }

    return _service.schedule(
      id: item.id,
      when: notifyAt,
      title: title,
      body: body,
    );
  }

  Future<void> _delete(Item item) async {
    await _service.cancel(item.id);
    setState(() => _items.remove(item));
  }

  Future<void> _toggleDone(Item item, bool done) async {
    if (done) {
      await _service.cancel(item.id);
    } else if (item.when.isAfter(DateTime.now())) {
      await _scheduleItem(item);
    }
    setState(() => item.done = done);
  }

  Future<void> _showTest() {
    return _service.showNow(
      title: 'Akthlon',
      body: 'Esta es una notificación de prueba.',
    );
  }

  IconData _iconFor(ItemType type) => switch (type) {
        ItemType.recordatorio => Icons.alarm,
        ItemType.tarea => Icons.check_circle_outline,
        ItemType.evento => Icons.event,
      };

  String _formatDate(DateTime d) {
    final time = TimeOfDay.fromDateTime(d).format(context);
    return '${d.day}/${d.month}/${d.year}  $time';
  }

  Widget _tokenCard() {
    return ValueListenableBuilder<String?>(
      valueListenable: PushService.instance.token,
      builder: (context, token, _) {
        return Card(
          child: ListTile(
            title: const Text('Token de push (FCM)'),
            subtitle: Text(
              token ?? 'Obteniendo token…',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: token == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: token));
                      _snack('Token copiado');
                    },
            ),
          ),
        );
      },
    );
  }

  Widget _itemTile(Item item) {
    final leading = item.type == ItemType.tarea
        ? Checkbox(
            value: item.done,
            onChanged: (v) => _toggleDone(item, v ?? false),
          )
        : Icon(_iconFor(item.type));

    return Card(
      child: ListTile(
        leading: leading,
        title: Text(
          item.title,
          style: item.done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(_formatDate(item.when)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Image.asset('img/logo_akthlon.jpeg', height: 140),
            Text(
              _granted
                  ? 'Notificaciones activadas'
                  : 'Notificaciones desactivadas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Zona horaria: ${_service.timeZoneName}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_granted)
              FilledButton.tonal(
                onPressed: _askPermission,
                child: const Text('Permitir notificaciones'),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _create(ItemType.recordatorio),
              icon: const Icon(Icons.alarm),
              label: const Text('Nuevo recordatorio'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _create(ItemType.tarea),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Nueva tarea pendiente'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _create(ItemType.evento),
              icon: const Icon(Icons.event),
              label: const Text('Nuevo evento'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _showTest,
              child: const Text('Probar notificación ahora'),
            ),
            const SizedBox(height: 16),
            _tokenCard(),
            const SizedBox(height: 24),
            Text('Mis pendientes',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              const Text('Todavía no has guardado nada.')
            else
              ..._items.map(_itemTile),
          ],
        ),
      ),
    );
  }
}
