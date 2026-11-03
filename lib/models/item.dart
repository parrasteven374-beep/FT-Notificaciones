enum ItemType { recordatorio, tarea, evento }

class Item {
  Item({
    required this.id,
    required this.type,
    required this.title,
    required this.when,
    this.done = false,
  });

  final int id;
  final ItemType type;
  final String title;
  final DateTime when;
  bool done;
}
