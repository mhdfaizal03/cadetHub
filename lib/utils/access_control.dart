import 'package:ncc_cadet/models/user_model.dart';

/// Returns a list of years that the given [user] is allowed to manage.
///
/// Logic:
/// - Officer / Senior Under Officer: Can manage ALL years (returns null).
/// - Under Officer: Can manage only years strictly below their own year.
///   - 3rd Year UO -> ['1st Year', '2nd Year']
///   - 2nd Year UO -> ['1st Year']
///   - 1st Year UO -> [] (Should theoretically not happen or manage none)
/// - Cadet: Should not be calling this (returns empty or relevant logic).
List<String>? getManageableYears(UserModel user) {
  if (user.role == 'officer' || user.rank == 'Senior Under Officer') {
    return null; // All years
  }

  if (user.rank == 'Under Officer') {
    // New Requirement: Under Officer manages ONLY their own year.
    if (user.year.isNotEmpty) {
      return [user.year];
    }
    return [];
  }

  // Fallback for others (e.g. Sgt, Cpl acting as helpers? Limit to none for now)
  // Or if logic dictates they can't manage anyone.
  return [];
}
