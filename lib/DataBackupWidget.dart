import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';

class DataBackupWidget extends StatelessWidget {
  const DataBackupWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BOUTON EXPORT (Copie le JSON dans le presse-papier)
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copier la sauvegarde (JSON)'),
          onPressed: () async {
            String? jsonString = await DatabaseHelper.instance.exportDatabaseToJsonString();
            if (jsonString != null) {
              await Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sauvegarde copiée dans le presse-papier !')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur lors de l\'exportation.')),
              );
            }
          },
        ),
        const SizedBox(height: 10),

        // BOUTON IMPORT (Ouvre une boîte de dialogue pour coller le JSON)
        OutlinedButton.icon(
          icon: const Icon(Icons.paste),
          label: const Text('Restaurer depuis le presse-papier'),
          onPressed: () {
            final TextEditingController pasteController = TextEditingController();

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Restaurer les données'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Colle ton JSON de sauvegarde ci-dessous :'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pasteController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Colle le texte ici...',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      bool success = await DatabaseHelper.instance.importDatabaseFromJsonString(pasteController.text);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Données restaurées avec succès !' : 'Erreur : JSON invalide.',
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
    );
  }
}