import 'package:intl/intl.dart';
import '../localization/app_strings.dart';

class DateHelper {
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime dateTime, {String format = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static String getApiFormat(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String getApiDateTimeFormat(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return S.yearsAgo((difference.inDays / 365).floor());
    } else if (difference.inDays > 30) {
      return S.monthsAgo((difference.inDays / 30).floor());
    } else if (difference.inDays > 0) {
      return S.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return S.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return S.minutesAgo(difference.inMinutes);
    } else {
      return S.justNow;
    }
  }
}

class NumberHelper {
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatNumber(num number) {
    final formatter = NumberFormat('#,##0');
    return formatter.format(number);
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

class ValidationHelper {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-()]+$').hasMatch(phone);
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return S.fieldRequired(fieldName);
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return S.emailIsRequired;
    }
    if (!isValidEmail(value)) {
      return S.invalidEmailFormat;
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return S.phoneIsRequired;
    }
    if (!isValidPhone(value)) {
      return S.invalidPhoneFormat;
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return S.passwordRequired;
    }
    if (value.length < 6) {
      return S.passwordTooShort;
    }
    return null;
  }
}

class HealthHelper {
  static double calculateBMI(double weight, double height) {
    // weight in kg, height in cm
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return S.underweight;
    if (bmi < 25) return S.normal;
    if (bmi < 30) return S.overweight;
    return S.obese;
  }

  static double calculateBMR(double weight, double height, int age, String gender) {
    // Mifflin-St Jeor Equation
    // weight in kg, height in cm
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  static double calculateDailyCalories(double bmr, String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return bmr * 1.2;
      case 'light':
        return bmr * 1.375;
      case 'moderate':
        return bmr * 1.55;
      case 'active':
        return bmr * 1.725;
      case 'very_active':
        return bmr * 1.9;
      default:
        return bmr * 1.2;
    }
  }
}
