import 'package:flutter/material.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor:Colors.transparent ,
        title: title,
        actions: actions,
        centerTitle: !isWide,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
