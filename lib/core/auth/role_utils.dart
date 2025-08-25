enum AppPlatform { mobile, web }

enum RolCanonico { 
  lider, 
  gerenteMgv, 
  gerentePais, 
  coordinadorMgv 
}

class RoleUtils {
  static String normalize(String s) => s
      .toUpperCase()
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('Ü', 'U')
      .replaceAll('Ñ', 'N')
      .replaceAll('/', ' / ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static RolCanonico? mapRol(String rolRaw) {
    final r = normalize(rolRaw);
    // Reemplazar guiones bajos por espacios para manejar ambos formatos
    final rWithSpaces = r.replaceAll('_', ' ');
    
    if (rWithSpaces == 'LIDER') return RolCanonico.lider;
    if (rWithSpaces == 'GERENTE MGV') return RolCanonico.gerenteMgv;
    if (rWithSpaces == 'COORDINADOR MGV') return RolCanonico.coordinadorMgv;
    if (rWithSpaces == 'GERENTE DE DISTRITO / PAIS') return RolCanonico.gerentePais;
    
    // También intentar con el formato original por si acaso
    if (r == 'GERENTE_MGV') return RolCanonico.gerenteMgv;
    if (r == 'COORDINADOR_MGV') return RolCanonico.coordinadorMgv;
    if (r == 'GERENTE_DE_DISTRITO_PAIS') return RolCanonico.gerentePais;
    
    return null;
  }

  static List<AppPlatform> plataformasParaRol(RolCanonico rol) {
    switch (rol) {
      case RolCanonico.lider:
        return [AppPlatform.mobile];
      case RolCanonico.gerenteMgv:
      case RolCanonico.gerentePais:
      case RolCanonico.coordinadorMgv:
        return [AppPlatform.mobile, AppPlatform.web];
    }
  }

  static String getUserKey(Map<String, dynamic> tokenData) {
    return tokenData['sub'] ?? tokenData['email'] ?? 'default_user';
  }
}