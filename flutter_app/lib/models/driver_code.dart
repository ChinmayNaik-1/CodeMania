class DriverCode {
  final String language;
  final String driverPrefix;
  final String driverSuffix;

  const DriverCode({
    required this.language,
    required this.driverPrefix,
    required this.driverSuffix,
  });

  factory DriverCode.fromJson(Map<String, dynamic> json) => DriverCode(
        language: json['language'] as String,
        driverPrefix: json['driver_prefix'] as String? ?? '',
        driverSuffix: json['driver_suffix'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'language': language,
        'driver_prefix': driverPrefix,
        'driver_suffix': driverSuffix,
      };
}
