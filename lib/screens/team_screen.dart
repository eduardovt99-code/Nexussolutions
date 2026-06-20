import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/database_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  bool _isLoading = true;
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    final workers = await DatabaseService().getAllWorkers();
    if (mounted) {
      setState(() {
        _workers = workers;
        _isLoading = false;
      });
    }
  }

  void _showWorkerDialog([Worker? worker]) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WorkerDialog(
        worker: worker,
        onSave: (w) async {
          await DatabaseService().saveWorker(w);
          _loadWorkers();
        },
      ),
    );
  }

  Future<void> _deleteWorker(Worker worker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Eliminar empleado', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${worker.name}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();
      setState(() => _isLoading = true);
      await DatabaseService().deleteWorker(worker.id);
      _loadWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'EQUIPO',
          style: TextStyle(color: AppTheme.brandBlack, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showWorkerDialog(),
              icon: const Icon(Icons.person_add, color: AppTheme.brandBlack, size: 18),
              label: const Text('ALTA EMPLEADO', style: TextStyle(color: AppTheme.brandBlack, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandYellow,
                foregroundColor: AppTheme.brandBlack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.deepCyan))
            : _workers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'NO HAY EMPLEADOS',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Da de alta a tu primer empleado.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.deepCyan,
                    onRefresh: _loadWorkers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _workers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final worker = _workers[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.brandYellow.withValues(alpha: 0.1),
                                child: Text(
                                  worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppTheme.brandYellow, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      worker.name,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.deepCyan.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            WorkerProfession.label(worker.profession).toUpperCase(),
                                            style: const TextStyle(color: AppTheme.deepCyan, fontSize: 10, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${worker.weeklyCapacityHours.toInt()}h semanales',
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary),
                                onPressed: () => _showWorkerDialog(worker),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                                onPressed: () => _deleteWorker(worker),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _WorkerDialog extends StatefulWidget {
  final Worker? worker;
  final Function(Worker) onSave;

  const _WorkerDialog({this.worker, required this.onSave});

  @override
  State<_WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends State<_WorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hoursController;
  late String _profession;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker?.name ?? '');
    _hoursController = TextEditingController(text: widget.worker?.weeklyCapacityHours.toString() ?? '40');
    _profession = widget.worker?.profession ?? WorkerProfession.albanileria;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final hours = double.tryParse(_hoursController.text) ?? 40.0;
      final worker = Worker(
        id: widget.worker?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: widget.worker?.ownerId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
        name: _nameController.text.trim(),
        profession: _profession,
        weeklyCapacityHours: hours,
      );
      widget.onSave(worker);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.worker != null;
    return AlertDialog(
      backgroundColor: AppTheme.surfaceLight,
      title: Text(isEditing ? 'Editar Empleado' : 'Alta de Empleado', style: const TextStyle(color: Colors.white)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre y Apellidos',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppTheme.brandBlack,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _profession,
                dropdownColor: AppTheme.brandBlack,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Empleo',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppTheme.brandBlack,
                ),
                items: WorkerProfession.labels.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _profession = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hoursController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas semanales (Capacidad)',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppTheme.brandBlack,
                ),
                validator: (val) => val == null || double.tryParse(val) == null ? 'Ingresa un número válido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandYellow),
          child: const Text('GUARDAR', style: TextStyle(color: AppTheme.brandBlack, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
