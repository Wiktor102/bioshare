import 'package:bioshare/common/custom_card.dart';
import 'package:bioshare/common/location_picker.dart';
import 'package:flutter/material.dart';

// common components
import './app_bar.dart';

class CreateFridge extends StatefulWidget {
  final Function() goToLogin;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  CreateFridge({
    required this.goToLogin,
    super.key,
  });

  @override
  State<CreateFridge> createState() => _CreateFridgeState();
}

class _CreateFridgeState extends State<CreateFridge> {
  String name = "";
  String address = "";
  String description = "";
  bool test = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: CustomAppBar(
            title: "Stwórz lodówkę",
            goToLogin: () {
              Navigator.of(context).pop();
              widget.goToLogin();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: widget._formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    onSaved: (newValue) => name = (newValue ?? ""),
                    decoration: gedInputDecoration(
                      context,
                      labelText: "Nazwa",
                      hintText: "Nazwij lodówkę",
                      icon: Icons.abc,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    onSaved: (newValue) => address = (newValue ?? ""),
                    decoration: gedInputDecoration(
                      context,
                      labelText: "Adres",
                      hintText: "",
                      icon: Icons.pin_drop,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    onSaved: (newValue) => description = (newValue ?? ""),
                    maxLines: null,
                    decoration: gedInputDecoration(
                      context,
                      labelText: "Opis",
                      hintText: "Jeśli chcesz możesz dodać opis",
                      icon: Icons.description,
                      borderRadius: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const CustomCard(
                      title: "Wskaż miejsce lodówki",
                      children: [
                        SizedBox(
                          height: 170,
                          child: LocationPicker(),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomCard(
                    title: "Inne",
                    children: [
                      ListTile(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Lodówka testowa"),
                            Tooltip(
                              key: widget._tooltipKey,
                              message: "Zaznacz to pole jeśli lodówka nie istnieje naprawdę",
                              showDuration: const Duration(seconds: 4),
                              triggerMode: TooltipTriggerMode.manual,
                              child: IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  widget._tooltipKey.currentState?.ensureTooltipVisible();
                                },
                              ),
                            ),
                          ],
                        ),
                        leading: const Icon(Icons.biotech),
                        trailing: Switch(
                          value: test,
                          onChanged: (newState) => setState(() {
                            test = newState;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.done),
        ),
      ),
    );
  }

  InputDecoration gedInputDecoration(
    BuildContext context, {
    required String labelText,
    required String hintText,
    required IconData icon,
    double borderRadius = 100,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      fillColor: Colors.white,
      icon: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
    );
  }
}
