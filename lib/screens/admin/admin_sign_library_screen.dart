import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import 'admin_upload_sign_screen.dart';

class AdminSignLibraryScreen extends StatelessWidget {
  const AdminSignLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getSignLibraryCategoriesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final categoryDocs = snapshot.data!.docs;
        
        // 1. "New Uploads" + Dynamic Categories
        final List<String> tabs = ["New Uploads"]; 
        final List<String> dynamicCategories = categoryDocs.map((doc) => doc['name'] as String).toList();
        tabs.addAll(dynamicCategories);

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Sign Library"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => showSearch(
                    context: context, 
                    delegate: SignSearchDelegate(firestoreService)
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add') _showAddCategoryDialog(context, firestoreService);
                    if (value == 'delete') _showDeleteCategoryDialog(context, firestoreService, categoryDocs);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'add', child: Text('Add Category Tab')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Category Tab')),
                  ],
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tabs.map((c) => Tab(text: c)).toList(),
              ),
            ),
            
            body: TabBarView(
              // REMOVED: physics: const NeverScrollableScrollPhysics(),
              // Now you can swipe left/right to change tabs
              children: tabs.map((currentTab) {
                return SignListByCategory(
                  currentTabName: currentTab, 
                  knownCategories: dynamicCategories,
                  firestoreService: firestoreService
                );
              }).toList(),
            ),

            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text("Upload New", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUploadSignScreen()),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, FirestoreService service) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g., Animals, Food..."),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                service.addSignLibraryCategory(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, FirestoreService service, List<QueryDocumentSnapshot> docs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final name = docs[i]['name'];
              return ListTile(
                title: Text(name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    service.deleteSignLibraryCategory(docs[i].id);
                    Navigator.pop(ctx);
                  },
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }
}

class SignListByCategory extends StatefulWidget {
  final String currentTabName;
  final List<String> knownCategories;
  final FirestoreService firestoreService;

  const SignListByCategory({
    super.key, 
    required this.currentTabName, 
    required this.knownCategories,
    required this.firestoreService
  });

  @override
  State<SignListByCategory> createState() => _SignListByCategoryState();
}

class _SignListByCategoryState extends State<SignListByCategory> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final Set<String> _selectedWords = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String word) {
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
        if (_selectedWords.isEmpty) _isSelectionMode = false;
      } else {
        _selectedWords.add(word);
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(String word) {
    setState(() {
      _isSelectionMode = true;
      _selectedWords.add(word);
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedWords.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isInbox = (widget.currentTabName == "New Uploads");
    
    final stream = isInbox
        ? widget.firestoreService.getAllSignsStream()
        : widget.firestoreService.getSignsByCategory(widget.currentTabName);

    return Column(
      children: [
        if (_isSelectionMode)
          Container(
            color: Colors.purple.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.close), onPressed: _cancelSelection),
                Text("${_selectedWords.length} Selected", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showBulkMoveDialog,
                  icon: const Icon(Icons.drive_file_move),
                  label: const Text("Move"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final allDocs = snapshot.data!.docs;
              
              List<QueryDocumentSnapshot> displayedDocs = allDocs;
              if (isInbox) {
                displayedDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['category'] as String?;
                  if (category == null || category.isEmpty || category == "New Uploads") return true;
                  return !widget.knownCategories.contains(category);
                }).toList();
              }

              if (displayedDocs.isEmpty) {
                return const Center(child: Text("No signs here.", style: TextStyle(color: Colors.grey)));
              }

              return ListView.separated(
                // CHANGED: Increased bottom padding to 160 so the FAB doesn't block the last item
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 160), 
                itemCount: displayedDocs.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = displayedDocs[index].data() as Map<String, dynamic>;
                  final word = data['word'] ?? displayedDocs[index].id;
                  final category = data['category'] ?? 'Uncategorized';
                  
                  final isSelected = _selectedWords.contains(word);

                  return ListTile(
                    tileColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isSelected ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
                    ),
                    
                    onLongPress: () => _enterSelectionMode(word),
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(word);
                      }
                    },

                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (val) => _toggleSelection(word),
                          )
                        : const CircleAvatar(
                            backgroundColor: Colors.purple,
                            child: Icon(Icons.accessibility_new, color: Colors.white),
                          ),
                    
                    title: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(category, style: TextStyle(color: Colors.grey[600])),
                    
                    trailing: _isSelectionMode ? null : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => widget.firestoreService.deleteSign(word),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showBulkMoveDialog() {
    final List<String> moveTargets = ["New Uploads", ...widget.knownCategories];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Move ${_selectedWords.length} items to..."),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moveTargets.length,
            itemBuilder: (ctx, i) {
              final cat = moveTargets[i];
              if (cat == widget.currentTabName) return const SizedBox.shrink();

              return ListTile(
                title: Text(cat),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.firestoreService.moveMultipleSigns(
                    _selectedWords.toList(), 
                    cat
                  );
                  _cancelSelection();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Moved items to '$cat'"))
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))],
      ),
    );
  }
}

class SignSearchDelegate extends SearchDelegate {
  final FirestoreService firestoreService;
  SignSearchDelegate(this.firestoreService);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
  ];

  @override
  Widget? buildLeading(BuildContext context) => 
    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) return const Center(child: Text("Type to search..."));

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.searchSigns(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['word']),
              subtitle: Text(data['category'] ?? 'Uncategorized'),
              onTap: () => close(context, null),
            );
          },
        );
      },
    );
  }
}