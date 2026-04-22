import 'package:flutter/material.dart';

/// 可爱卡通风格主题 - AI 日程助手
class AppTheme {
  // ==================== 基础颜色 ====================
  // 奶油色系
  static const Color primaryCream = Color(0xFFFFF8F0);
  static const Color primaryBeige = Color(0xFFFFF0E6);
  
  // 主色调 - 温暖的珊瑚橙
  static const Color accentPeach = Color(0xFFFF9B71);
  static const Color accentPeachLight = Color(0xFFFFD4C4);
  static const Color accentPeachDark = Color(0xFFE87B50);
  
  // 辅助色 - 马卡龙色系
  static const Color accentPink = Color(0xFFFFB5BA);
  static const Color accentLavender = Color(0xFFE0D4FF);
  static const Color accentMint = Color(0xFFA8E6CF);
  static const Color accentYellow = Color(0xFFFFE66D);
  static const Color accentBlue = Color(0xFFA8D8FF);
  
  // 文字颜色
  static const Color textBrown = Color(0xFF5D4E37);
  static const Color textLightBrown = Color(0xFF8B7355);
  static const Color textCream = Color(0xFFFFFDF8);
  
  // 背景与卡片
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFFFF5EE);
  static const Color dividerColor = Color(0xFFFFE8DD);
  static const Color shadowColor = Color(0x1A5D4E37);
  
  // AI 助手颜色
  static const Color aiBubbleBg = Color(0xFFFFE5DC);
  static const Color userBubbleBg = Color(0xFFFF9B71);
  
  // 状态颜色
  static const Color success = Color(0xFFA8E6CF);
  static const Color warning = Color(0xFFFFE66D);
  static const Color error = Color(0xFFFFB5BA);
  static const Color info = Color(0xFFA8D8FF);

  // ==================== 优先级颜色 ====================
  static const List<Color> priorityColors = [
    Color(0xFFE8E0D5),  // 无
    Color(0xFFA8E6CF),  // 低
    Color(0xFFA8D8FF),  // 中低
    Color(0xFFFFE66D),  // 中
    Color(0xFFFFD4A8),  // 中高
    Color(0xFFFFB5BA),  // 高
  ];

  // ==================== 对话气泡颜色 ====================
  static const List<Color> chatBubbleColors = [
    Color(0xFFFFE5DC),  // AI 气泡
    Color(0xFFFF9B71), // 用户气泡
  ];

  // 暖色系马卡龙调色板
  static const List<Color> warmPastelColors = [
    Color(0xFFFFE5DC),  // 珊瑚粉
    Color(0xFFA8E6CF), // 薄荷绿
    Color(0xFFA8D8FF), // 天空蓝
    Color(0xFFFFE66D), // 柠檬黄
    Color(0xFFE0D4FF), // 薰衣草紫
    Color(0xFFFFD4A8), // 杏子橙
  ];

  // ==================== AI 助手小狐狸配色 ====================
  static const Color foxOrange = Color(0xFFFF9B50);
  static const Color foxLight = Color(0xFFFFDCC0);
  static const Color foxDark = Color(0xFFE87030);

  // ==================== 渐变色 ====================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF9B71), Color(0xFFFFB5BA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiBubbleGradient = LinearGradient(
    colors: [Color(0xFFFFE5DC), Color(0xFFFFD4C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== 圆角半径 ====================
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;
  static const double radiusCircle = 100.0;

  // ==================== 阴影 ====================
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadowColor.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: shadowColor.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // ==================== 主题数据 ====================
  static ThemeData get cuteTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentPeach,
      scaffoldBackgroundColor: primaryCream,
      colorScheme: ColorScheme.light(
        primary: accentPeach,
        primaryContainer: accentPeachLight,
        secondary: accentPink,
        secondaryContainer: accentLavender,
        tertiary: accentMint,
        surface: cardBackground,
        onPrimary: textCream,
        onSecondary: textBrown,
        onSurface: textBrown,
        error: error,
      ),
      
      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: primaryCream,
        foregroundColor: textBrown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: textBrown,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        iconTheme: const IconThemeData(
          color: textBrown,
          size: 24,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPeach,
          foregroundColor: textCream,
          elevation: 0,
          shadowColor: shadowColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircle),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textBrown,
          side: const BorderSide(color: accentPeach, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCircle),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPeach,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: accentPeach, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle: TextStyle(
          color: textLightBrown.withOpacity(0.5),
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          color: textLightBrown,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: accentPeach,
        unselectedItemColor: textLightBrown.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // 复选框主题
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPeach;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textCream),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: accentPeach, width: 2),
      ),
      
      // Switch 主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPeach;
          }
          return Colors.grey[300];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentPeachLight;
          }
          return Colors.grey[200];
        }),
      ),
      
      // 浮动操作按钮主题
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentPeach,
        foregroundColor: textCream,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Snackbar 主题
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textBrown,
        contentTextStyle: const TextStyle(
          color: textCream,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // 对话框主题
      dialogTheme: DialogTheme(
        backgroundColor: cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        titleTextStyle: const TextStyle(
          color: textBrown,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: textLightBrown,
          fontSize: 15,
          height: 1.5,
        ),
      ),
      
      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      
      // 文字主题
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textBrown,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          color: textBrown,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: textBrown,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textBrown,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textBrown,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: textLightBrown,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textBrown,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textLightBrown,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: textLightBrown,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: textBrown,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ==================== 可爱组件扩展 ====================

/// 可爱风格的输入框装饰
class CuteInputDecoration {
  static InputDecoration chatInput({
    required String hintText,
    required Widget suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppTheme.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
        borderSide: const BorderSide(color: AppTheme.accentPeach, width: 2),
      ),
      hintStyle: TextStyle(
        color: AppTheme.textLightBrown.withOpacity(0.5),
        fontSize: 15,
      ),
      suffixIcon: suffixIcon,
    );
  }
}

/// 可爱风格的卡片装饰
class CuteCardDecoration {
  static BoxDecoration aiBubble() {
    return BoxDecoration(
      color: AppTheme.aiBubbleBg,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(AppTheme.radiusLarge),
        bottomLeft: Radius.circular(AppTheme.radiusLarge),
        bottomRight: Radius.circular(AppTheme.radiusLarge),
      ),
      boxShadow: AppTheme.softShadow,
    );
  }

  static BoxDecoration userBubble() {
    return BoxDecoration(
      color: AppTheme.userBubbleBg,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppTheme.radiusLarge),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(AppTheme.radiusLarge),
        bottomRight: Radius.circular(AppTheme.radiusLarge),
      ),
      boxShadow: AppTheme.softShadow,
    );
  }

  static BoxDecoration eventCard({Color? color}) {
    return BoxDecoration(
      color: color ?? AppTheme.cardBackground,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      boxShadow: AppTheme.softShadow,
    );
  }
}
