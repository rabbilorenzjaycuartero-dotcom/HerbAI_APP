import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../services/admin_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/report_service.dart';
import '../utils/name_input.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

/// Lists the admin accounts (max 3) and lets an admin create a new admin
/// account or remove another admin. The main admin and the signed-in admin
/// cannot be removed (also enforced by the server).
class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  List<AdminAccount>? _admins;
  String? _error;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final admins = await AdminService.listAdmins();
      if (mounted) setState(() => _admins = admins);
    } catch (e) {
      debugPrint('Load admins failed: $e');
      if (mounted) setState(() => _error = context.trRead('report_load_failed'));
    }
  }

  Future<void> _confirmRemove(AdminAccount admin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('remove_admin_title')),
        content: Text('${context.tr('remove_admin_confirm')}\n\n${admin.name}\n${admin.email}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('remove'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _removing.add(admin.uid));
    final error = await AdminService.removeAdmin(admin.uid);
    if (!mounted) return;
    setState(() => _removing.remove(admin.uid));
    _snack(error ?? '${admin.email} ${context.trRead('admin_removed')}', isError: error != null);
    if (error == null) _load();
  }

  Future<void> _openAddForm() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _AddAdminSheet(),
    );
    if (added == true && mounted) {
      _snack(context.trRead('admin_added'));
      _load();
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : AppTheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admins = _admins;
    final myUid = FirebaseAuthService.currentUser?.uid;
    // Only the main admin may create admin accounts (also enforced by the server).
    final iAmMain = admins?.any((a) => a.uid == myUid && a.isMain) ?? false;
    final canAdd = iAmMain && admins != null && admins.length < maxAdmins;
    return Scaffold(
      appBar: CustomAppBar(title: context.tr('manage_admins')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${admins?.length ?? '-'} / $maxAdmins ${context.tr('admins_used')}. ${context.tr('admins_rules')}',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Center(child: Text(_error!))
              else if (admins == null)
                const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
              else
                for (final admin in admins)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          admin.isMain ? Icons.verified_user_rounded : Icons.person_outline,
                          color: AppTheme.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              admin.name.isEmpty ? admin.email : admin.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (admin.isMain) _tag(context.tr('main_admin'), AppTheme.primary),
                          if (admin.uid == myUid) _tag(context.tr('you_label'), Colors.blueGrey),
                        ],
                      ),
                      subtitle: Text(
                        [
                          admin.email,
                          if (admin.addedByEmail.isNotEmpty)
                            '${context.tr('added_by')} ${admin.addedByEmail} · ${ReportService.formatDate(admin.createdAt)}',
                        ].join('\n'),
                      ),
                      isThreeLine: admin.addedByEmail.isNotEmpty,
                      trailing: (admin.isMain || admin.uid == myUid)
                          ? null
                          : _removing.contains(admin.uid)
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  tooltip: context.tr('remove'),
                                  icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade400),
                                  onPressed: () => _confirmRemove(admin),
                                ),
                    ),
                  ),
              const SizedBox(height: 12),
              if (admins != null && iAmMain)
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: canAdd ? context.tr('add_admin') : context.tr('admin_limit_reached'),
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: canAdd ? _openAddForm : null,
                    borderRadius: 30,
                  ),
                )
              else if (admins != null)
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('only_main_can_add'),
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

/// Bottom sheet form: name, email, password and confirm password for the new
/// admin account (same name and password rules as Create Account).
class _AddAdminSheet extends StatefulWidget {
  const _AddAdminSheet();

  @override
  State<_AddAdminSheet> createState() => _AddAdminSheetState();
}

class _AddAdminSheetState extends State<_AddAdminSheet> {
  static final RegExp _special = RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=~`\[\];'/\\]''');
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _passwordError(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return context.trRead('please_enter_password');
    if (v.length < 12) return context.trRead('password_min_length');
    if (!RegExp(r'[A-Z]').hasMatch(v)) return context.trRead('password_needs_uppercase');
    if (!RegExp(r'[a-z]').hasMatch(v)) return context.trRead('password_needs_lowercase');
    if (!RegExp(r'[0-9]').hasMatch(v)) return context.trRead('password_needs_number');
    if (!_special.hasMatch(v)) return context.trRead('password_needs_special');
    return null;
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await AdminService.createAdmin(
      name: normalizeName(_name.text),
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.tr('add_admin'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                context.tr('add_admin_help'),
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                hintText: context.tr('full_name_hint'),
                controller: _name,
                enabled: !_saving,
                prefixIcon: const Icon(Icons.person_outlined),
                textCapitalization: TextCapitalization.words,
                inputFormatters: nameInputFormatters,
                validator: (value) => validateName(value, context),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                hintText: context.tr('email_hint'),
                controller: _email,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return context.trRead('please_enter_email');
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                    return context.trRead('please_enter_valid_email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                hintText: context.tr('password_hint'),
                controller: _password,
                enabled: !_saving,
                obscureText: _obscure,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: _passwordError,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                hintText: context.tr('confirm_password_hint'),
                controller: _confirm,
                enabled: !_saving,
                obscureText: _obscure,
                prefixIcon: const Icon(Icons.lock_outlined),
                validator: (value) {
                  if ((value ?? '').isEmpty) return context.trRead('please_confirm_password');
                  if (value != _password.text) return context.trRead('passwords_do_not_match');
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: context.tr('create_admin_account'),
                  onPressed: _saving ? null : _submit,
                  isLoading: _saving,
                  borderRadius: 30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
