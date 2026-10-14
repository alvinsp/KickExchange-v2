class DataMasking {
  static String maskAccountNumber(String? accNumber) {
    if (accNumber == null || accNumber.isEmpty) return '-';
    if (accNumber.length < 8) return '****';
    final prefix = accNumber.substring(0, 4);
    final suffix = accNumber.substring(accNumber.length - 4);
    return '$prefix **** **** $suffix';
  }

  static String maskEmail(String? email) {
    if (email == null || !email.contains('@')) return email ?? '-';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '${name[0]}*@$domain';
    return '${name.substring(0, 2)}***@$domain';
  }

  static String maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return '****';
    final prefix = digits.substring(0, 4);
    final suffix = digits.substring(digits.length - 4);
    return '$prefix-****-$suffix';
  }
}
