class Validators {
  // Validator for name (used in Register and Contact)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name cannot be empty';
    }
    if (value.length < 3) {
      return 'Name must have at least 3 characters';
    }
    return null;
  }

  // Validator for email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    // Standard regex for email validation
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  // Validator for password (used in Login and Register)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password too weak (min 6 characters)';
    }
    return null;
  }

  // Validator for phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number cannot be empty';
    }
    if (value.length < 10) {
      return 'Invalid phone number';
    }
    return null;
  }

  // General validator for non-empty fields
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }
}