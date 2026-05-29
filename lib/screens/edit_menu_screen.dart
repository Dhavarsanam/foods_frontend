import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data.dart';
import '../models.dart';
import '../widgets/footer.dart';

// ── Edit Menu Screen ────────────────────────────────────────────────────────
class EditMenuScreen extends StatefulWidget {
  final List<Color> gradientColors;
  final Color accentColor;

  const EditMenuScreen({super.key, required this.gradientColors, required this.accentColor});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedImagePath;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
    setState(() => _selectedImagePath = saved.path);
  }

  void _showImageSourceSheet({Function(String)? onPicked}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE87722))),
              title: const Text('Gallery-லிருந்து தேர்வு', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                if (onPicked != null) {
                  final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                    onPicked(saved.path);
                  }
                } else { _pickImage(ImageSource.gallery); }
              },
            ),
            ListTile(
              leading: Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2ECC71))),
              title: const Text('Camera-ல் எடு', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                if (onPicked != null) {
                  final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (picked != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                    final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                    onPicked(saved.path);
                  }
                } else { _pickImage(ImageSource.camera); }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ பெயர் மற்றும் விலை சரியாக இல்லை!'),
        backgroundColor: Color(0xFFE74C3C), behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      menu.add(Item(name, price, image: _selectedImagePath));
      _nameController.clear();
      _priceController.clear();
      _selectedImagePath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $name சேர்க்கப்பட்டது!'),
      backgroundColor: const Color(0xFF2ECC71), behavior: SnackBarBehavior.floating,
    ));
  }

  void _deleteItem(int index) {
    final name = menu[index].name;
    setState(() => menu.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🗑️ $name நீக்கப்பட்டது!'),
      backgroundColor: const Color(0xFFE74C3C), behavior: SnackBarBehavior.floating,
    ));
  }

  void _editItem(int index) {
    final item = menu[index];
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    String? editImagePath = item.image;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text('Item திருத்து', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE87722))),
                            title: const Text('Gallery-லிருந்து தேர்வு', style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () async {
                              Navigator.pop(context);
                              final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                              if (picked != null) {
                                final appDir = await getApplicationDocumentsDirectory();
                                final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                                final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                                setDialogState(() => editImagePath = saved.path);
                                setState(() => menu[index].image = saved.path);
                              }
                            },
                          ),
                          ListTile(
                            leading: Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2ECC71))),
                            title: const Text('Camera-ல் எடு', style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () async {
                              Navigator.pop(context);
                              final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                              if (picked != null) {
                                final appDir = await getApplicationDocumentsDirectory();
                                final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                                final saved = await File(picked.path).copy(p.join(appDir.path, fileName));
                                setDialogState(() => editImagePath = saved.path);
                                setState(() => menu[index].image = saved.path);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 80, width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                  child: _buildImageWidget(editImagePath),
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: _inputDecoration('Item பெயர்')),
              const SizedBox(height: 10),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration('விலை')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888)))),
            GestureDetector(
              onTap: () {
                final newName = nameCtrl.text.trim();
                final newPrice = double.tryParse(priceCtrl.text.trim());
                if (newName.isNotEmpty && newPrice != null) {
                  setState(() { menu[index] = Item(newName, newPrice, image: menu[index].image); });
                  Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? path) {
    if (path == null) {
      return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_a_photo_rounded, color: Color(0xFFE87722), size: 28),
        SizedBox(height: 4),
        Text('Image', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      ]);
    }
    if (path.startsWith('assets/')) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(path, fit: BoxFit.cover, width: double.infinity));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(path), fit: BoxFit.cover, width: double.infinity));
  }

  Widget _buildListImage(String? path) {
    if (path == null) {
      return Container(width: 48, height: 48,
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.fastfood_rounded, color: Color(0xFFCCCCCC), size: 24));
    }
    if (path.startsWith('assets/')) {
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(path, width: 48, height: 48, fit: BoxFit.cover));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(path), width: 48, height: 48, fit: BoxFit.cover));
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: const Color(0xFFF5F5F5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.8)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)]),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Edit Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text('Add, edit or remove items', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  ]),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFE87722).withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(width: 32, height: 32,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.add_rounded, color: Color(0xFFE87722), size: 18)),
                            const SizedBox(width: 10),
                            const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          ]),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _showImageSourceSheet(),
                            child: Container(
                              height: 100, width: double.infinity,
                              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
                              child: _buildImageWidget(_selectedImagePath),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(controller: _nameController, decoration: _inputDecoration('Item Name')),
                          const SizedBox(height: 10),
                          TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: _inputDecoration('Price')),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _addItem,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFE87722)]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.add_rounded, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Add to Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Text('Current Menu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE87722), borderRadius: BorderRadius.circular(20)),
                        child: Text('${menu.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ...List.generate(menu.length, (index) {
                      final item = menu[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(children: [
                          _buildListImage(item.image),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('₹${item.price}', style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                          ])),
                          GestureDetector(
                            onTap: () => _editItem(index),
                            child: Container(width: 36, height: 36,
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFE87722))),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteItem(index),
                            child: Container(width: 36, height: 36,
                                decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.delete_rounded, size: 16, color: Colors.redAccent)),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}