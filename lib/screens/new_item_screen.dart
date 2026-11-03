import 'package:material_ui/material_ui.dart';

import '../models/item.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key, required this.type});

  final ItemType type;

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _titleController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;

  String get _screenTitle => switch (widget.type) {
        ItemType.recordatorio => 'Nuevo recordatorio',
        ItemType.tarea => 'Nueva tarea pendiente',
        ItemType.evento => 'Nuevo evento',
      };

  String get _hint => switch (widget.type) {
        ItemType.recordatorio => '¿Qué quieres recordar?',
        ItemType.tarea => '¿Qué tienes pendiente?',
        ItemType.evento => 'Nombre del evento',
      };

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return _snack('Escribe un título');
    if (_date == null || _time == null) {
      return _snack('Elige la fecha y la hora');
    }
    final when = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    if (!when.isAfter(DateTime.now())) {
      return _snack('Esa fecha y hora ya pasaron');
    }
    Navigator.pop(
      context,
      Item(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        type: widget.type,
        title: title,
        when: when,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date == null
        ? 'Elegir fecha'
        : '${_date!.day}/${_date!.month}/${_date!.year}';
    final timeText = _time == null ? 'Elegir hora' : _time!.format(context);

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: _hint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(dateText),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time),
            label: Text(timeText),
          ),
          if (widget.type == ItemType.evento) ...[
            const SizedBox(height: 12),
            const Text('Te avisaremos 15 minutos antes del evento.'),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
    );
  }
}
