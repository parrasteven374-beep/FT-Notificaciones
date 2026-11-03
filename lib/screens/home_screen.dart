import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/item.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import 'new_item_screen.dart';

const _coral = Color(0xFFFF5A52);
const _ink = Color(0xFF1B2029);
const _coralSoft = Color(0xFFFFE3E0);

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

  Future<void> _toggleDone(Item item) async {
    final done = !item.done;
    if (done) {
      await _service.cancel(item.id);
    } else if (item.when.isAfter(DateTime.now())) {
      await _scheduleItem(item);
    }
    setState(() => item.done = done);
  }

  Future<void> _showToken() {
    return showDialog<void>(
      context: context,
      builder: (context) => ValueListenableBuilder<String?>(
        valueListenable: PushService.instance.token,
        builder: (context, token, _) => AlertDialog(
          title: const Text('Token de push (FCM)'),
          content: SelectableText(token ?? 'Obteniendo token…'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: token == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: token));
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _snack('Token copiado');
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTest() async {
    final controller =
        TextEditingController(text: 'Esta es una notificación de prueba.');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Probar notificación'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Texto de la notificación',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    await _service.showNow(title: 'Akthlon', body: text);
  }

  void _openFromDrawer(Future<void> Function() action) {
    Navigator.pop(context);
    action();
  }

  IconData _iconFor(ItemType type) => switch (type) {
        ItemType.recordatorio => Icons.alarm,
        ItemType.tarea => Icons.assignment_outlined,
        ItemType.evento => Icons.event,
      };

  Color _colorFor(ItemType type) => switch (type) {
        ItemType.recordatorio => _coral,
        ItemType.tarea => _ink,
        ItemType.evento => const Color(0xFFE8847E),
      };

  (IconData, Color) _status(Item item) {
    if (item.done) return (Icons.check_circle, const Color(0xFF2E9E6B));
    if (item.when.isBefore(DateTime.now())) {
      return (Icons.error_outline, _coral);
    }
    return (Icons.schedule, _ink.withValues(alpha: 0.55));
  }

  Widget _metaLine(IconData icon, String text) {
    final muted = _ink.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final time = TimeOfDay.fromDateTime(d).format(context);
    return '${d.day}/${d.month}/${d.year}  $time';
  }

  Widget _logo() {
    return Center(
      child: ClipRect(
        child: Align(
          widthFactor: 0.56,
          heightFactor: 0.56,
          child: Image.asset('img/logo_akthlon.jpeg', width: 300),
        ),
      ),
    );
  }

  Widget _tile({
    required String label,
    required IconData icon,
    required Color color,
    required Color onColor,
    required VoidCallback onTap,
    Color? border,
  }) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 124,
            padding: const EdgeInsets.all(16),
            decoration: border == null
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border, width: 1.5),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: onColor, size: 30),
                Text(
                  label,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    return Column(
      children: [
        Row(
          children: [
            _tile(
              label: 'Nuevo recordatorio',
              icon: Icons.alarm,
              color: _coral,
              onColor: Colors.white,
              onTap: () => _create(ItemType.recordatorio),
            ),
            const SizedBox(width: 14),
            _tile(
              label: 'Nueva tarea pendiente',
              icon: Icons.check_circle_outline,
              color: _ink,
              onColor: Colors.white,
              onTap: () => _create(ItemType.tarea),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _tile(
              label: 'Nuevo evento',
              icon: Icons.event,
              color: _coralSoft,
              onColor: _ink,
              onTap: () => _create(ItemType.evento),
            ),
            const SizedBox(width: 14),
            _tile(
              label: 'Probar notificación',
              icon: Icons.notifications_active_outlined,
              color: Colors.white,
              onColor: _ink,
              border: _ink.withValues(alpha: 0.15),
              onTap: _showTest,
            ),
          ],
        ),
      ],
    );
  }

  Widget _permissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: _coralSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined, color: _ink),
          const SizedBox(width: 12),
          const Expanded(child: Text('Notificaciones desactivadas')),
          TextButton(
            onPressed: _askPermission,
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(Item item) {
    final status = _status(item);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(item),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: _coral,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _ink.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _colorFor(item.type),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(item.type), color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      decoration:
                          item.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _metaLine(Icons.notifications_none, _formatDate(item.when)),
                  _metaLine(Icons.edit_calendar_outlined,
                      'Creado ${_formatDate(item.createdAt)}'),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: _ink,
                  onPressed: () => _delete(item),
                ),
                GestureDetector(
                  onTap:
                      item.type == ItemType.tarea ? () => _toggleDone(item) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(status.$1, color: status.$2, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: const Color(0xFFFAF6F1),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Menú',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: _ink),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('Token'),
              subtitle: const Text('Ver y copiar'),
              onTap: () => _openFromDrawer(_showToken),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Probar notificación'),
              subtitle: const Text('Con tu propio texto'),
              onTap: () => _openFromDrawer(_showTest),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: _drawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            _logo(),
            const SizedBox(height: 12),
            if (!_granted) _permissionBanner(),
            _grid(),
            const SizedBox(height: 28),
            Text(
              'PENDIENTES',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Todavía no has guardado nada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _ink.withValues(alpha: 0.5)),
                ),
              )
            else
              ..._items.map(_itemCard),
          ],
        ),
      ),
    );
  }
}
