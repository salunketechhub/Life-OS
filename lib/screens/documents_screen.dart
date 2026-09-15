// lib/screens/documents_screen.dart
import 'package:flutter/material.dart';
import '../models/document_item.dart';
import '../services/document_storage_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentStorageService _storageService = DocumentStorageService();
  List<DocumentItem> _documents = [];
  DocumentCategory? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final loaded = await _storageService.loadDocuments();
    if (mounted) {
      setState(() {
        _documents = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _addDocument(
    String title,
    String docNumber,
    DocumentCategory category,
    DateTime? expiryDate,
  ) async {
    final newDoc = DocumentItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      documentNumber: docNumber.trim(),
      category: category,
      expiryDate: expiryDate,
    );

    setState(() {
      _documents.insert(0, newDoc);
    });
    await _storageService.saveDocuments(_documents);
  }

  Future<void> _updateDocument(DocumentItem updatedDoc) async {
    final index = _documents.indexWhere((d) => d.id == updatedDoc.id);
    if (index != -1) {
      setState(() {
        _documents[index] = updatedDoc;
      });
      await _storageService.saveDocuments(_documents);
    }
  }

  Future<void> _deleteDocument(String id) async {
    setState(() {
      _documents.removeWhere((doc) => doc.id == id);
    });
    await _storageService.saveDocuments(_documents);
  }

  bool _isExpiringSoon(DateTime? date) {
    if (date == null) return false;
    final daysUntil = date.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 30;
  }

  void _showDocumentFormSheet({DocumentItem? docToEdit}) {
    final isEditing = docToEdit != null;
    final titleController = TextEditingController(text: docToEdit?.title ?? '');
    final numberController =
        TextEditingController(text: docToEdit?.documentNumber ?? '');
    DocumentCategory chosenCategory =
        docToEdit?.category ?? DocumentCategory.personal;
    DateTime? chosenExpiry = docToEdit?.expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Document Record' : 'Add New Document Record',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Document Name (e.g., Passport, PAN)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        hintText: 'Document / Registration Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DocumentCategory>(
                      initialValue: chosenCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: DocumentCategory.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => chosenCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            chosenExpiry == null
                                ? 'Set Expiry Date'
                                : '${chosenExpiry!.day}/${chosenExpiry!.month}/${chosenExpiry!.year}',
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: chosenExpiry ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2045),
                            );
                            if (picked != null) {
                              setModalState(() => chosenExpiry = picked);
                            }
                          },
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isEmpty) return;

                            if (isEditing) {
                              _updateDocument(DocumentItem(
                                id: docToEdit.id,
                                title: title,
                                documentNumber: numberController.text.trim(),
                                category: chosenCategory,
                                expiryDate: chosenExpiry,
                              ));
                            } else {
                              _addDocument(
                                title,
                                numberController.text,
                                chosenCategory,
                                chosenExpiry,
                              );
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text(isEditing ? 'Update Record' : 'Save Record'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredDocs = _selectedCategory == null
        ? _documents
        : _documents.where((d) => d.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Vault - Life OS'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDocumentFormSheet(),
        child: const Icon(Icons.note_add),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('ALL'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 6),
                ...DocumentCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(cat.name.toUpperCase()),
                      selected: _selectedCategory == cat,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? cat : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredDocs.isEmpty
                ? const Center(
                    child: Text('No documents stored in this category.'),
                  )
                : ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final isExpiring = _isExpiringSoon(doc.expiryDate);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isExpiring
                                ? Colors.red.shade100
                                : Colors.blue.shade100,
                            child: Icon(
                              Icons.folder_outlined,
                              color: isExpiring ? Colors.red : Colors.blue,
                            ),
                          ),
                          title: Text(
                            doc.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (doc.documentNumber.isNotEmpty)
                                Text('ID: ${doc.documentNumber}'),
                              if (doc.expiryDate != null)
                                Text(
                                  'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                                  style: TextStyle(
                                    color: isExpiring
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                    fontWeight: isExpiring
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () =>
                                    _showDocumentFormSheet(docToEdit: doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteDocument(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}