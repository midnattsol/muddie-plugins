# Plugins de Muddie

Plugins para Muddie, un cliente de
MUD. Cada carpeta de aquí es un plugin para un MUD: sus scripts, sus reglas
y una plantilla de perfil que lo usa.

Muddie descarga los plugins por sí mismo. Lee `plugins.zip` de la última
versión publicada de este repositorio, así que no hay nada que instalar a
mano. English: [README.md](README.md).

## Contribuir

Un plugin es una carpeta en el nivel superior con:

- `plugin.toml`: el nombre, una descripción corta (`about`), los MUD para
  los que es (`hosts` y `names`), y `muddie`, la versión más antigua de
  Muddie que puede instalarlo, como `X.Y.Z`.
- `rules.toml` y `template.toml`: las reglas que configura y la plantilla
  de perfil para el MUD.
- uno o más scripts `*.luau`.

Nada más, y sin carpetas dentro de la carpeta del plugin. Antes de abrir una
pull request, ejecuta:

```sh
python3 tools/check.py   # revisa cada carpeta de plugin
python3 tools/api.py     # revisa el uso de la API de Muddie, con luau-analyze
python3 tools/pack.py    # crea plugins.zip en la raíz del repositorio
```

Ambos necesitan Python 3.11 o posterior. Los mensajes de commit siguen
[Conventional Commits](https://www.conventionalcommits.org/).

## Publicar versiones

Las versiones las gestiona [release-please](https://github.com/googleapis/release-please-action).
Un commit en `main` actualiza una pull request de versión. Al fusionar esa
pull request se crea la versión y su etiqueta, y el CI sube `plugins.zip` a
ella.

## Licencia

Se distribuye bajo cualquiera de estas dos licencias, a tu elección:

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
- Licencia MIT ([LICENSE-MIT](LICENSE-MIT))
