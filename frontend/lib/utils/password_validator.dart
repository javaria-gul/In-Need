class PasswordStrength {
  final bool hasUpper, hasLower, hasNum, hasSpecial, hasLen;
  const PasswordStrength({required this.hasUpper,required this.hasLower,required this.hasNum,required this.hasSpecial,required this.hasLen});
  bool get isStrong => hasUpper&&hasLower&&hasNum&&hasSpecial&&hasLen;
  int get percent { int c=0; if(hasUpper)c++;if(hasLower)c++;if(hasNum)c++;if(hasSpecial)c++;if(hasLen)c++; return c*20; }
  String get label { final p=percent; if(p<=20)return'Very Weak';if(p<=40)return'Weak';if(p<=60)return'Fair';if(p<=80)return'Good';return'Strong'; }
}

class PasswordValidator {
  static PasswordStrength validate(String p) => PasswordStrength(
    hasUpper:   p.contains(RegExp(r'[A-Z]')),
    hasLower:   p.contains(RegExp(r'[a-z]')),
    hasNum:     p.contains(RegExp(r'[0-9]')),
    hasSpecial: p.contains(RegExp(r'[@$!%*?&]')),
    hasLen:     p.length >= 8,
  );
  static bool isStrongPassword(String p) => validate(p).isStrong;
  static bool isValidPhone(String p) { final d=p.replaceAll(RegExp(r'\D'),''); return d.length>=10&&d.length<=11; }
  static bool isValidName(String n) { final t=n.trim(); return t.length>=3&&RegExp(r'^[a-zA-Z\s]+$').hasMatch(t); }
  static String sanitize(String s) => s.trim().replaceAll(RegExp(r'[<>"\`]'),'');
}
