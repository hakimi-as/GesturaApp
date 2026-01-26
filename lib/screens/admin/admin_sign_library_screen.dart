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
        
        // "New Uploads" + Dynamic Categories
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
                    if (value == 'migrate') _showMigrationDialog(context, firestoreService);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'add', child: Text('Add Category Tab')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Category Tab')),
                    const PopupMenuItem(value: 'migrate', child: Text('⚡ Optimize Database')),
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

  void _showMigrationDialog(BuildContext context, FirestoreService service) {
    showDialog(
      context: context,
      builder: (ctx) => _MigrationDialog(firestoreService: service),
    );
  }
}

/// Migration Dialog with Progress
class _MigrationDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  const _MigrationDialog({required this.firestoreService});

  @override
  State<_MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<_MigrationDialog> {
  bool _isMigrating = false;
  int _current = 0;
  int _total = 0;
  String _status = "";
  Map<String, int>? _result;
  String? _error;

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _current = 0;
      _total = 0;
      _status = "Starting...";
      _error = null;
    });

    try {
      final result = await widget.firestoreService.migrateSignsToSeparateDataBatched(
        onProgress: (current, total, status) {
          if (mounted) {
            setState(() {
              _current = current;
              _total = total;
              _status = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isMigrating = false;
          _result = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMigrating = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("⚡ Optimize Database"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isMigrating && _result == null && _error == null) ...[
              const Text(
                "This will separate animation data from metadata, "
                "making the sign library load much faster.\n\n"
                "This processes 20 signs at a time to avoid timeouts.\n\n"
                "⚠️ For 742 signs, this will take about 15-20 minutes.",
                style: TextStyle(fontSize: 14),
              ),
            ],
            if (_isMigrating) ...[
              Text("Progress: $_current / $_total", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _total > 0 ? _current / _total : null,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Keep this tab open. Do not close the browser.",
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
            if (_error != null) ...[
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 10),
              Text("Error: $_error", style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              const Text("You can try running it again - it will skip already migrated signs."),
            ],
            if (_result != null) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 10),
              Text("✅ Migrated: ${_result!['migrated']}"),
              Text("⏭️ Skipped: ${_result!['skipped']} (already optimized)"),
              Text("❌ Failed: ${_result!['failed']}"),
              if (_result!['migrated']! > 0) ...[
                const SizedBox(height: 10),
                const Text(
                  "🎉 Sign Library should now load much faster!",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (!_isMigrating && _result == null && _error == null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _runMigration,
            child: const Text("Start Migration"),
          ),
        ],
        if (_isMigrating)
          TextButton(
            onPressed: null, // Disabled while running
            child: const Text("Please wait..."),
          ),
        if (_result != null || _error != null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
      ],
    );
  }
}

/// Optimized Sign List with Pagination
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

  // Selection state
  final Set<String> _selectedWords = {};
  bool _isSelectionMode = false;

  // Pagination state
  final List<Map<String, dynamic>> _signs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  
  // Initial load flag
  bool _initialLoadDone = false;

  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadSigns();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near the bottom
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadSigns();
    }
  }

  Future<void> _loadSigns() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final isInbox = (widget.currentTabName == "New Uploads");
      
      Query query = FirebaseFirestore.instance.collection('signs');
      
      if (!isInbox) {
        query = query.where('category', isEqualTo: widget.currentTabName);
      }
      
      query = query.orderBy('word').limit(_pageSize);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;
        
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String? ?? '';
          
          // For "New Uploads" tab, filter out signs that have a known category
          if (isInbox) {
            if (category.isEmpty || 
                category == "New Uploads" || 
                !widget.knownCategories.contains(category)) {
              _signs.add({
                'id': doc.id,
                'word': data['word'] ?? doc.id,
                'category': category.isEmpty ? 'Uncategorized' : category,
                'snapshot': doc,
              });
            }
          } else {
            _signs.add({
              'id': doc.id,
              'word': data['word'] ?? doc.id,
              'category': category,
              'snapshot': doc,
            });
          }
        }
        
        // If we filtered everything in inbox, try to load more
        if (isInbox && _signs.isEmpty && snapshot.docs.isNotEmpty) {
          _hasMore = true;
        }
      }
      
      _initialLoadDone = true;
    } catch (e) {
      debugPrint("Error loading signs: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    setState(() {
      _signs.clear();
      _lastDocument = null;
      _hasMore = true;
      _initialLoadDone = false;
    });
    await _loadSigns();
  }

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

  Future<void> _deleteSign(String word) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Sign?"),
        content: Text("Are you sure you want to delete '$word'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.firestoreService.deleteSign(word);
      setState(() {
        _signs.removeWhere((s) => s['word'] == word);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$word' deleted")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Selection Mode Header
        if (_isSelectionMode)
          Container(
            color: Colors.purple.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelSelection,
                ),
                Text(
                  "${_selectedWords.length} Selected",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showBulkMoveDialog,
                  icon: const Icon(Icons.drive_file_move),
                  label: const Text("Move"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        // Sign List
        Expanded(
          child: !_initialLoadDone
              ? const Center(child: CircularProgressIndicator())
              : _signs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                        itemCount: _signs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading indicator at the bottom
                          if (index >= _signs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final sign = _signs[index];
                          final word = sign['word'] as String;
                          final category = sign['category'] as String;
                          final isSelected = _selectedWords.contains(word);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              tileColor: isSelected
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: isSelected
                                    ? const BorderSide(color: Colors.blue, width: 2)
                                    : BorderSide.none,
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
                              title: Text(
                                word,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                category,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: _isSelectionMode
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteSign(word),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            widget.currentTabName == "New Uploads"
                ? "No new uploads to organize"
                : "No signs in this category",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
          ),
        ],
      ),
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
                  
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Moving signs...")),
                  );
                  
                  await widget.firestoreService.moveMultipleSigns(
                    _selectedWords.toList(),
                    cat,
                  );
                  
                  // Remove moved items from current list
                  setState(() {
                    _signs.removeWhere((s) => _selectedWords.contains(s['word']));
                  });
                  
                  _cancelSelection();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Moved ${_selectedWords.length} items to '$cat'")),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }
}

/// Search Delegate for Signs
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
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Type to search for signs...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.searchSigns(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No signs found for '$query'",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.accessibility_new, color: Colors.white),
                ),
                title: Text(
                  data['word'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data['category'] ?? 'Uncategorized'),
                onTap: () => close(context, null),
              ),
            );
          },
        );
      },
    );
  }
}