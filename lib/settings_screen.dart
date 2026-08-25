import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Ton thème clair propre
      appBar: AppBar(
        title: const Text('Paramètres', style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Sauvegarde et Données',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),

          // --- CONTENEUR POUR FAIRE PROPRE (Style de carte) ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // BOUTON EXPORT
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Colors.blueAccent),
                  title: const Text('Copier la sauvegarde (JSON)', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Copie tes données dans le presse-papier', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () async {
                    String? jsonString = await DatabaseHelper.instance.exportDatabaseToJsonString();
                    if (jsonString != null) {
                      await Clipboard.setData(ClipboardData(text: jsonString));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sauvegarde copiée dans le presse-papier !'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur lors de l\'exportation.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // BOUTON IMPORT
                ListTile(
                  leading: const Icon(Icons.paste_rounded, color: Colors.orangeAccent),
                  title: const Text('Restaurer une sauvegarde', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Colle ton JSON pour restaurer les données', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    final TextEditingController pasteController = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Restaurer les données'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Colle le texte JSON de ta sauvegarde ci-dessous :'),
                            const SizedBox(height: 10),
                            TextField(
                              controller: pasteController,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '{"version": 1, ...}',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              bool success = await DatabaseHelper.instance.importDatabaseFromJsonString(pasteController.text);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success ? 'Données restaurées avec succès !' : 'Erreur : JSON invalide ou corrompu.',
                                  ),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            },
                            child: const Text('Importer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}