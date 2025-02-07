import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:paisa/src/core/extensions/transaction_extension.dart';
import 'package:paisa/src/domain/debt/entities/transaction.dart';

import '../../../../../main.dart';
import '../../../../core/common.dart';
import '../../../../core/enum/debt_type.dart';
import '../../../../data/debt/models/transactions_model.dart';
import '../../../widgets/paisa_bottom_sheet.dart';
import '../../../widgets/paisa_text_field.dart';
import '../../cubit/debts_cubit.dart';
import '../../widgets/debt_toggle_buttons_widget.dart';

class AddOrEditDebtPage extends StatefulWidget {
  const AddOrEditDebtPage({
    super.key,
    this.debtId,
  });
  final String? debtId;

  @override
  State<AddOrEditDebtPage> createState() => _AddOrEditDebtPageState();
}

class _AddOrEditDebtPageState extends State<AddOrEditDebtPage> {
  late final bool isUpdate = widget.debtId == null;
  final DebtsBloc debtBloc = getIt.get();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final nameController = TextEditingController();
  final descController = TextEditingController();
  @override
  void initState() {
    super.initState();
    debtBloc.add(FetchDebtOrCreditFromIdEvent(widget.debtId));
  }

  @override
  void dispose() {
    amountController.dispose();
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => debtBloc,
      child: BlocConsumer(
        bloc: debtBloc,
        listener: (context, state) {
          if (state is DebtsAdded) {
            GoRouter.of(context).pop();
          } else if (state is DebtsSuccessState) {
            amountController.text = state.debt.amount.toString();
            amountController.selection = TextSelection.collapsed(
              offset: state.debt.amount.toString().length,
            );

            nameController.text = state.debt.name.toString();
            nameController.selection = TextSelection.collapsed(
              offset: state.debt.name.toString().length,
            );

            descController.text = state.debt.description.toString();
            descController.selection = TextSelection.collapsed(
              offset: state.debt.description.toString().length,
            );
          } else if (state is DebtErrorState) {
            context.showMaterialSnackBar(
              state.errorString,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              color: Theme.of(context).colorScheme.onErrorContainer,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: context.materialYouAppBar(
              context.loc.addDebtLabel,
              actions: [
                isUpdate
                    ? const SizedBox.shrink()
                    : IconButton(
                        onPressed: () => paisaAlertDialog(
                          context,
                          title: Text(context.loc.dialogDeleteTitleLabel),
                          child: RichText(
                            text: TextSpan(
                              text: context.loc.deleteDebtOrCreditLabel,
                              children: const [
                                TextSpan(
                                  text: 'Are you sure?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          confirmationButton: TextButton(
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            onPressed: () {
                              debtBloc.add(DeleteDebtEvent(
                                  int.tryParse(widget.debtId!) ?? 0));
                            },
                            child: const Text('Delete'),
                          ),
                        ).then((value) => context.pop()),
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
              ],
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        DebtToggleButtonsWidget(debtsBloc: debtBloc),
                        const SizedBox(height: 16),
                        AmountWidget(controller: amountController),
                        const SizedBox(height: 16),
                        NameWidget(controller: nameController),
                        const SizedBox(height: 16),
                        DescriptionWidget(controller: descController),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  BlocBuilder(
                    bloc: debtBloc,
                    buildWhen: (previous, current) =>
                        current is SelectedDateState,
                    builder: (context, state) {
                      String? startDate, endDate;
                      if (state is SelectedDateState) {
                        startDate = state.startDateTime.formattedDate;
                        endDate = state.endDateTime.formattedDate;
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: DatePickerWidget(
                              onSelected: (date) =>
                                  debtBloc.currentDateTime = date,
                              title: context.loc.startDateLabel,
                              subtitle: startDate ?? context.loc.validDateLabel,
                              icon: MdiIcons.calendarStart,
                              lastDate: DateTime.now(),
                              firstDate: DateTime(2000),
                            ),
                          ),
                          Expanded(
                            child: DatePickerWidget(
                              onSelected: (date) =>
                                  debtBloc.currentDueDateTime = date,
                              title: context.loc.dueDateLabel,
                              subtitle: endDate ?? context.loc.validDateLabel,
                              icon: MdiIcons.calendarEnd,
                              lastDate: DateTime(2050),
                              firstDate: DateTime.now(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  ListTile(
                    title: Text(
                      context.loc.transactionHistoryLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ValueListenableBuilder<Box<TransactionsModel>>(
                    valueListenable:
                        getIt.get<Box<TransactionsModel>>().listenable(),
                    builder: (context, value, child) {
                      final int? parentId = int.tryParse(widget.debtId ?? '');
                      if (parentId == null) return const SizedBox.shrink();
                      final List<Transaction> transactions =
                          value.getTransactionsFromId(parentId);

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (_, index) {
                          final Transaction transaction = transactions[index];
                          return ListTile(
                            leading: IconButton(
                              onPressed: () {
                                debtBloc.add(
                                  DeleteTransactionEvent(transaction.superId!),
                                );
                              },
                              icon: const Icon(Icons.delete),
                            ),
                            title: Text(transaction.now.formattedDate),
                            trailing: Text(transaction.amount.toCurrency()),
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    final isValid = _formKey.currentState!.validate();
                    if (!isValid) {
                      return;
                    }
                    debtBloc.add(AddOrUpdateEvent(isUpdate));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                  ),
                  child: Text(
                    context.loc.addLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:
                          Theme.of(context).textTheme.titleLarge?.fontSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DatePickerWidget extends StatefulWidget {
  const DatePickerWidget({
    super.key,
    required this.onSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lastDate,
    required this.firstDate,
  });
  final Function(DateTime) onSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime lastDate;
  final DateTime firstDate;

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late String subtitle = widget.subtitle;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      horizontalTitleGap: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () async {
        final result = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
        );
        if (result == null) return;
        widget.onSelected.call(result);
        setState(() {
          subtitle = result.formattedDate;
        });
      },
      leading: Icon(widget.icon),
      title: Text(widget.title),
      subtitle: Text(subtitle),
    );
  }
}

class NameWidget extends StatelessWidget {
  const NameWidget({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PaisaTextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      hintText: context.loc.nameLabel,
      validator: (value) {
        if (value!.length >= 2) {
          return null;
        } else {
          return context.loc.validNameLabel;
        }
      },
      onChanged: (value) =>
          BlocProvider.of<DebtsBloc>(context).currentName = value,
    );
  }
}

class DescriptionWidget extends StatelessWidget {
  const DescriptionWidget({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PaisaTextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      hintText: context.loc.descriptionLabel,
      validator: (value) {
        if (value!.length >= 3) {
          return null;
        } else {
          return context.loc.validDescriptionLabel;
        }
      },
      onChanged: (value) =>
          BlocProvider.of<DebtsBloc>(context).currentDescription = value,
    );
  }
}

class AmountWidget extends StatelessWidget {
  const AmountWidget({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PaisaTextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      hintText: context.loc.amountLabel,
      onChanged: (value) {
        double? amount = double.tryParse(value);
        BlocProvider.of<DebtsBloc>(context).currentAmount = amount;
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value!.isNotEmpty) {
          return null;
        } else {
          return context.loc.validAmountLabel;
        }
      },
    );
  }
}
