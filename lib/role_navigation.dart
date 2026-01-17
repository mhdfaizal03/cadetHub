import 'package:flutter/material.dart';
import 'package:ncc_cadet/cadet/cadet_navbar.dart';
import 'package:ncc_cadet/officer/officer_dashboard.dart';
import 'package:ncc_cadet/officer/officer_navbar.dart';

import 'package:ncc_cadet/models/user_model.dart';

void navigateByRole(BuildContext context, UserModel user) {
  if (user.role == "officer" ||
      (user.role == "cadet" &&
          (user.rank == "Senior Under Officer" ||
              user.rank == "Under Officer"))) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OfficerNavBar()),
      (route) => false,
    );
  } else {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CadetNavbar()),
      (route) => false,
    );
  }
}
