import 'models.dart';

List<Item> menu = [
  // 🍽️ Breakfast Basics
  Item("Idli",            10,  image: "assets/images/Idli.png"),
  Item("Pongal",          35,  image: "assets/images/Pongal.png"),
  Item("Onion Oothappam", 25,  image: "assets/images/OnionOothappam.png"),

  // 🥞 Dosa Varieties
  Item("Dosa",            30,  image: "assets/images/dosa.png"),
  Item("Special Dosa",    30,  image: "assets/images/Specialdosa.png"),
  Item("Podi Dosa",       30,  image: "assets/images/Podidosa.png"),
  Item("Plain Dosa",      30,  image: "assets/images/Plaindosa.png"),
  Item("Masaal Dosa",     50,  image: "assets/images/Masaaldosa.png"),
  Item("Onion Dosa",      45,  image: "assets/images/Oniondosa.png"),
  Item("Ghee Roast",      60,  image: "assets/images/Gheeroast.png"),
  Item("Set Dosa",        40,  image: "assets/images/Setdosa.png"),
  Item("Rava Dosa",       50,  image: "assets/images/Ravadosa.png"),

  // 🍞 Breads
  Item("Poori Masaal",    40,  image: "assets/images/Poorimasaal.png"),
  Item("Veg Kothu",       40,  image: "assets/images/Vegkothu.png"),
  Item("Onion Adai",      20,  image: "assets/images/Onionadai.png"),
  Item("Chappathi",       25,  image: "assets/images/Chappathi.png"),
  Item("Parotta",         12,  image: "assets/images/Parotta.png"),

  // 🥗 Extras & Sides
  Item("Idiyappam",       10,  image: "assets/images/Idiyappam.png"),

  // ☕ Beverages
  Item("Vada",            15,  image: "assets/images/Vada.png"),
  Item("Sambar Vada",     20,  image: "assets/images/Sambarvada.png"),
];

const List<String> subLabels = ['A', 'B'];

// Main tables — dynamically sized; call rebuildTables() after changing count
List<TableData> tables = _buildMainTables(8);
Map<int, List<TableData>> subTables = _buildSubTables(8);

List<TableData> _buildMainTables(int count) => [
  for (int i = 1; i <= count; i++) TableData(i, '$i'),
];

Map<int, List<TableData>> _buildSubTables(int count) => {
  for (int i = 1; i <= count; i++)
    i: [for (final sub in subLabels) TableData(i, '$i$sub')],
};

/// Call this when admin changes table count (from settings)
void rebuildTables(int count) {
  tables = _buildMainTables(count);
  subTables = _buildSubTables(count);
}

/// Order tracker — tableNo 0
final TableData orderTable = TableData(0, '0');

/// Each confirmed order bill history
final List<Map<String, dynamic>> orderBillHistory = [];