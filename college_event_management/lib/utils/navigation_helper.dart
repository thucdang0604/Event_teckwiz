import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void safePop(BuildContext context, {String fallbackRoute = '/home'}) {
  try {
    if (GoRouter.of(context).canPop() || Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
  } catch (_) {
    // ignore and fallback
  }
  context.go(fallbackRoute);
}
