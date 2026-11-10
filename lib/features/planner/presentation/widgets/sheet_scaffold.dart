import 'package:flutter/material.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/features/planner/presentation/planner_view_model.dart';
import 'package:provider/provider.dart';

/// Membuka bottom sheet Planner yang berbagi [PlannerViewModel] yang sama.
Future<T?> showPlannerSheet<T>(BuildContext context, {required Widget child}) {
  final vm = context.read<PlannerViewModel>();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ChangeNotifierProvider.value(value: vm, child: child),
  );
}

/// Kerangka bottom sheet: handle bar, judul, dan padding keyboard.
class SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const SheetScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

String? requiredValidator(String? value, {String label = 'Judul'}) {
  if (value == null || value.trim().isEmpty) return '$label wajib diisi';
  if (value.trim().length > 120) return '$label maksimal 120 karakter';
  return null;
}
