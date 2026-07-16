enum ResourceType {
  video('video', 'Videos'),
  pdf('pdf', 'PDF'),
  form('formulario', 'Formularios'),
  simulator('simulacro', 'Simulacros'),
  post('publicacion', 'Publicaciones'),
  announcement('anuncio', 'Anuncios');

  const ResourceType(this.code, this.label);

  final String code;
  final String label;

  static ResourceType? tryParse(String value) {
    for (final type in values) {
      if (type.code == value.trim().toLowerCase()) {
        return type;
      }
    }
    return null;
  }
}
