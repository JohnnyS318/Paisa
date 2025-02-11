import 'package:flutter/material.dart';

import '../../../../core/enum/filter_budget.dart';

class OverviewTabletPage extends StatelessWidget {
  const OverviewTabletPage({
    super.key,
    required this.valueNotifier,
    required this.child,
  });

  final ValueNotifier<FilterExpense> valueNotifier;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(body: child);
}
