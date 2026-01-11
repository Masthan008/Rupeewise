import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../core/utils/category_icons.dart';

/// Categories management page
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      await _categoryService.seedDefaultCategories();
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddCategoryDialog(),
    );

    if (result != null) {
      try {
        await _categoryService.addCategory(
          name: result['name']!,
          icon: result['icon'] ?? 'category',
          color: result['color'] ?? '#4CAF50',
        );
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category added')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete default categories')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _categoryService.deleteCategory(category.id);
        await _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: _categories.isEmpty
                  ? const Center(child: Text('No categories'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final color = _parseColor(category.color);
                        final icon = CategoryIcons.getIcon(category.icon);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withAlpha(51),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(category.name),
                            subtitle: category.isDefault
                                ? const Text('Default')
                                : const Text('Custom'),
                            trailing: category.isDefault
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteCategory(category),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Dialog to add a new category with icon selection
class _AddCategoryDialog extends StatefulWidget {
  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'category';
  String _selectedColor = '#4CAF50';

  final List<String> _colors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7',
    '#3F51B5', '#2196F3', '#00BCD4', '#009688',
    '#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B',
    '#FFC107', '#FF9800', '#FF5722', '#795548',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            const Text('Select Icon'),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: CategoryIcons.getAllIcons().length,
                itemBuilder: (context, index) {
                  final entry = CategoryIcons.getAllIcons()[index];
                  final isSelected = entry.key == _selectedIcon;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = entry.key;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((colorHex) {
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                final isSelected = colorHex == _selectedColor;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'icon': _selectedIcon,
                'color': _selectedColor,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
