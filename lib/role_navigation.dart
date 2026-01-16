import 'package:flutter/material.dart';
import 'package:ncc_cadet/cadet/cadet_navbar.dart';
import 'package:ncc_cadet/officer/officer_dashboard.dart';
import 'package:ncc_cadet/officer/officer_navbar.dart';

void navigateByRole(BuildContext context, String role) {
  if (role == "officer") {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OfficerNavBar()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CadetNavbar()),
    );
  }
}
