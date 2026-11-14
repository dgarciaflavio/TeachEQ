import 'package:flutter/material.dart';

import 'analyzer_screen.dart';
import 'checklist_screen.dart';
import 'emergency_screen.dart';
import 'eq_screen.dart';
import 'gain_screen.dart';
import 'generator_screen.dart';
import 'guide_screen.dart';
import 'presets_screen.dart';
import 'projects_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _abrir(BuildContext context, Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('TeachEQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _abrir(context, const EmergencyScreen()),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 40, color: cs.onErrorContainer),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Deu problema',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onErrorContainer)),
                          const SizedBox(height: 4),
                          Text('Microfonia, caixa parada, mic mudo, zumbido...',
                              style: TextStyle(color: cs.onErrorContainer)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.onErrorContainer),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _Atalho(
                icone: Icons.mic,
                titulo: 'Analisador',
                subtitulo: 'Microfonia, dB e sala',
                onTap: () => _abrir(context, const AnalyzerScreen()),
              ),
              _Atalho(
                icone: Icons.equalizer,
                titulo: 'Equalizador',
                subtitulo: 'Simule a mesa',
                onTap: () => _abrir(context, const EqScreen()),
              ),
              _Atalho(
                icone: Icons.school_outlined,
                titulo: 'Guia',
                subtitulo: 'O que cada frequência faz',
                onTap: () => _abrir(context, const GuideScreen()),
              ),
              _Atalho(
                icone: Icons.tune,
                titulo: 'Presets',
                subtitulo: 'Equalizações prontas',
                onTap: () => _abrir(context, const PresetsScreen()),
              ),
              _Atalho(
                icone: Icons.event_note_outlined,
                titulo: 'Eventos',
                subtitulo: 'Projetos salvos',
                onTap: () => _abrir(context, const ProjectsScreen()),
              ),
              _Atalho(
                icone: Icons.checklist,
                titulo: 'Checklist',
                subtitulo: 'Montagem e passagem',
                onTap: () => _abrir(context, const ChecklistScreen()),
              ),
              _Atalho(
                icone: Icons.surround_sound_outlined,
                titulo: 'Gerador',
                subtitulo: 'Ruído rosa e tons',
                onTap: () => _abrir(context, const GeneratorScreen()),
              ),
              _Atalho(
                icone: Icons.tune_outlined,
                titulo: 'Ganho certo',
                subtitulo: 'Volume na ordem certa',
                onTap: () => _abrir(context, const GainScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icone, size: 32, color: cs.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  Text(subtitulo,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
