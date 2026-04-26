// lib/screens/owner/owner_menu_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/menu.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../services/mess_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class OwnerMenuEditorScreen extends ConsumerStatefulWidget {
  const OwnerMenuEditorScreen({super.key});

  @override
  ConsumerState<OwnerMenuEditorScreen> createState() =>
      _OwnerMenuEditorScreenState();
}

class _OwnerMenuEditorScreenState extends ConsumerState<OwnerMenuEditorScreen> {
  String _selectedDay = AppConstants.daysOfWeek[DateTime.now().weekday - 1];
  String _selectedMeal = AppConstants.mealTypeLunch;
  List<Menu> _menus = [];
  bool _loading = true;
  String? _messId;

  final _itemCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) return;

    final mess =
        await ref.read(messServiceProvider).getMessByOwner(profile.id);
    if (mess == null || !mounted) return;

    _messId = mess.id;
    final menus = await MessService().getMenuForMess(mess.id);
    if (mounted) setState(() { _menus = menus; _loading = false; });
  }

  Menu? get _currentMenu {
    try {
      return _menus.firstWhere(
        (m) => m.dayOfWeek == _selectedDay && m.mealType == _selectedMeal,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _addItem() async {
    final item = _itemCtrl.text.trim();
    if (item.isEmpty || _messId == null) return;

    final current = _currentMenu;
    final newItems = [...(current?.items ?? []), item];
    final data = {
      'id': current?.id ?? const Uuid().v4(),
      'mess_id': _messId,
      'day_of_week': _selectedDay,
      'meal_type': _selectedMeal,
      'items': newItems,
    };

    await MessService().upsertMenu(data);
    _itemCtrl.clear();
    await _loadData();
  }

  Future<void> _removeItem(String item) async {
    final current = _currentMenu;
    if (current == null) return;

    final newItems = current.items.where((i) => i != item).toList();
    await MessService().upsertMenu({
      'id': current.id,
      'mess_id': _messId,
      'day_of_week': _selectedDay,
      'meal_type': _selectedMeal,
      'items': newItems,
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Edit Menu',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day selector
                  Text('Day',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.daysOfWeek.map((day) {
                        final isSelected = day == _selectedDay;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedDay = day),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: isSelected
                                    ? AppTheme.primaryShadow
                                    : [],
                              ),
                              child: Text(
                                day.substring(0, 3),
                                style: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Meal type toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _MealToggle(
                          label: '☀️ Lunch',
                          isSelected: _selectedMeal ==
                              AppConstants.mealTypeLunch,
                          onTap: () => setState(() => _selectedMeal =
                              AppConstants.mealTypeLunch),
                        ),
                        const SizedBox(width: 4),
                        _MealToggle(
                          label: '🌙 Dinner',
                          isSelected: _selectedMeal ==
                              AppConstants.mealTypeDinner,
                          onTap: () => setState(() => _selectedMeal =
                              AppConstants.mealTypeDinner),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu items header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppTheme.primaryColor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_selectedDay.substring(0, 3)} · ${_selectedMeal == "lunch" ? "Lunch" : "Dinner"}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Items list
                  Expanded(
                    child: _currentMenu == null ||
                            _currentMenu!.items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fastfood_rounded,
                                    size: 48,
                                    color: AppTheme.textLight),
                                const SizedBox(height: 14),
                                Text('No items yet',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary)),
                                Text('Add some items below!',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _currentMenu!.items.length,
                            itemBuilder: (context, i) {
                              final item = _currentMenu!.items[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _removeItem(item),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.close_rounded,
                                            color: AppTheme.errorColor,
                                            size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Add item row
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemCtrl,
                            style: GoogleFonts.inter(),
                            decoration: InputDecoration(
                              labelText: 'Add menu item',
                              labelStyle: GoogleFonts.inter(fontSize: 14),
                              prefixIcon: const Icon(
                                  Icons.fastfood_rounded,
                                  size: 20),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                            ),
                            onFieldSubmitted: (_) => _addItem(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_rounded,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _MealToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _MealToggle(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? AppTheme.softShadow : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
