import 'package:flutter/material.dart';

class DockerColors extends ThemeExtension<DockerColors> {
  final Color statusRunning;
  final Color statusExited;
  final Color statusCreated;
  final Color statusRestarting;
  final Color statusPaused;
  final Color sectionTitle;
  final Color labelText;
  final Color valueText;
  final Color copyButton;
  final Color inUseBorder;
  final Color inUseBackground;
  final Color mountedBorder;
  final Color mountedBackground;
  final Color fileIcon;
  final Color dirIcon;

  const DockerColors({
    required this.statusRunning,
    required this.statusExited,
    required this.statusCreated,
    required this.statusRestarting,
    required this.statusPaused,
    required this.sectionTitle,
    required this.labelText,
    required this.valueText,
    required this.copyButton,
    required this.inUseBorder,
    required this.inUseBackground,
    required this.mountedBorder,
    required this.mountedBackground,
    required this.fileIcon,
    required this.dirIcon,
  });

  static const light = DockerColors(
    statusRunning: Color(0xFF2E7D32),
    statusExited: Color(0xFFC62828),
    statusCreated: Color(0xFF0A84FF),
    statusRestarting: Color(0xFFEF6C00),
    statusPaused: Color(0xFFF9A825),
    sectionTitle: Color(0xFF0A84FF),
    labelText: Color(0xFF6E7278),
    valueText: Color(0xFF1A1C1E),
    copyButton: Color(0xFF9EA2A8),
    inUseBorder: Color(0xFF2E7D32),
    inUseBackground: Color(0xFFE8F5E9),
    mountedBorder: Color(0xFF2E7D32),
    mountedBackground: Color(0xFFE8F5E9),
    fileIcon: Color(0xFF8E9298),
    dirIcon: Color(0xFF0A84FF),
  );

  static const dark = DockerColors(
    statusRunning: Color(0xFF66BB6A),
    statusExited: Color(0xFFFF8A80),
    statusCreated: Color(0xFF4DA3FF),
    statusRestarting: Color(0xFFFFB74D),
    statusPaused: Color(0xFFFFD54F),
    sectionTitle: Color(0xFF4DA3FF),
    labelText: Color(0xFFAEB2BB),
    valueText: Color(0xFFE2E5EC),
    copyButton: Color(0xFF90959F),
    inUseBorder: Color(0xFF81C784),
    inUseBackground: Color(0xFF1B5E20),
    mountedBorder: Color(0xFF81C784),
    mountedBackground: Color(0xFF1B5E20),
    fileIcon: Color(0xFF9EA3AD),
    dirIcon: Color(0xFF4DA3FF),
  );

  @override
  DockerColors copyWith({
    Color? statusRunning,
    Color? statusExited,
    Color? statusCreated,
    Color? statusRestarting,
    Color? statusPaused,
    Color? sectionTitle,
    Color? labelText,
    Color? valueText,
    Color? copyButton,
    Color? inUseBorder,
    Color? inUseBackground,
    Color? mountedBorder,
    Color? mountedBackground,
    Color? fileIcon,
    Color? dirIcon,
  }) {
    return DockerColors(
      statusRunning: statusRunning ?? this.statusRunning,
      statusExited: statusExited ?? this.statusExited,
      statusCreated: statusCreated ?? this.statusCreated,
      statusRestarting: statusRestarting ?? this.statusRestarting,
      statusPaused: statusPaused ?? this.statusPaused,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      labelText: labelText ?? this.labelText,
      valueText: valueText ?? this.valueText,
      copyButton: copyButton ?? this.copyButton,
      inUseBorder: inUseBorder ?? this.inUseBorder,
      inUseBackground: inUseBackground ?? this.inUseBackground,
      mountedBorder: mountedBorder ?? this.mountedBorder,
      mountedBackground: mountedBackground ?? this.mountedBackground,
      fileIcon: fileIcon ?? this.fileIcon,
      dirIcon: dirIcon ?? this.dirIcon,
    );
  }

  @override
  DockerColors lerp(ThemeExtension<DockerColors>? other, double t) {
    if (other is! DockerColors) return this;
    return DockerColors(
      statusRunning: Color.lerp(statusRunning, other.statusRunning, t)!,
      statusExited: Color.lerp(statusExited, other.statusExited, t)!,
      statusCreated: Color.lerp(statusCreated, other.statusCreated, t)!,
      statusRestarting: Color.lerp(statusRestarting, other.statusRestarting, t)!,
      statusPaused: Color.lerp(statusPaused, other.statusPaused, t)!,
      sectionTitle: Color.lerp(sectionTitle, other.sectionTitle, t)!,
      labelText: Color.lerp(labelText, other.labelText, t)!,
      valueText: Color.lerp(valueText, other.valueText, t)!,
      copyButton: Color.lerp(copyButton, other.copyButton, t)!,
      inUseBorder: Color.lerp(inUseBorder, other.inUseBorder, t)!,
      inUseBackground: Color.lerp(inUseBackground, other.inUseBackground, t)!,
      mountedBorder: Color.lerp(mountedBorder, other.mountedBorder, t)!,
      mountedBackground: Color.lerp(mountedBackground, other.mountedBackground, t)!,
      fileIcon: Color.lerp(fileIcon, other.fileIcon, t)!,
      dirIcon: Color.lerp(dirIcon, other.dirIcon, t)!,
    );
  }
}

class DockerResourceIconColor {
  static const images = Color(0xFF00897B);
  static const networks = Color(0xFFE65100);
  static const stacks = Color(0xFF00695C);
  static const volumes = Color(0xFF4E342E);
  static const envVars = Color(0xFF37474F);
  static const ports = Color(0xFF283593);

  const DockerResourceIconColor._();
}
