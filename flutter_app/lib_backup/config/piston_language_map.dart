class PistonRuntime {
  const PistonRuntime({
    required this.language,
    required this.version,
    required this.monacoLanguage,
  });

  final String language;
  final String version;
  final String monacoLanguage;
}

const Map<String, PistonRuntime> pistonLanguageMap = {
  'Python 3': PistonRuntime(
    language: 'python',
    version: '3.10.0',
    monacoLanguage: 'python',
  ),
  'C++17': PistonRuntime(
    language: 'cpp',
    version: '10.2.0',
    monacoLanguage: 'cpp',
  ),
  'Java 15': PistonRuntime(
    language: 'java',
    version: '15.0.2',
    monacoLanguage: 'java',
  ),
  'JavaScript': PistonRuntime(
    language: 'javascript',
    version: '18.15.0',
    monacoLanguage: 'javascript',
  ),
};
