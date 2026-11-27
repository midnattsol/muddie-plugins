# Plugins de Muddie

Plugins para Muddie, un cliente de
MUD. Cada carpeta de aquí es un plugin para un MUD: sus scripts, sus reglas
y una plantilla de perfil que lo usa.

Muddie descarga los plugins por sí mismo. Lee `plugins.zip` de la última
versión publicada de este repositorio, así que no hay nada que instalar a
mano. English: [README.md](README.md).

## Reinos de Leyenda

Sus indicadores, canales en pestañas y mapa, por GMCP (escribe en el juego
`consentir gmcp on`). Además, para jugar de oído, cada parte en su script, que
se puede apagar sola en el editor:

- **Modos de juego** (`modes.luau`): original, combate, experiencia e
  inactivo, cada uno lee más o menos del juego. Se cambian con `modo` (el
  siguiente), `modo xp`, `modo?`, o desde la paleta.
  `silencio` deja de leer el juego y lo vuelve a leer.
- **Listas** (`history.luau`): lo dicho en la sala (`hsala`), las telepatías
  (`htels`) y lo que pasa en combate (`heventos`), para recorrerlas y copiar
  una. `r texto` responde por telepatía al último que te escribió; `rt` elige
  a quién.
- **Vida** (`life.luau`): cuánta pierdes o ganas, avisos por debajo de la
  mitad, del 30 % y del 10 %, y los últimos cambios (`hvida`). Un golpe de más
  de 200 saca del modo experiencia.
- **Quién llega y se va** (`movement.luau`), dicho corto y guardado (`hmov`),
  y un objetivo: el primero de tu `nick x`, u `obj nombre`; se avisa cuando
  está en la sala.
- **Corrector** (`corrector.luau`): lo que escriben otros jugadores se lee
  sin signos que molestan ni la raza tras el nombre, sin cambiar lo que se ve.
- **Teclas como en VipMud** (`keys.luau`), apagadas hasta que las enciendas
  con `teclasrl` o desde la paleta: Alt con u, i, o, j, k, l, 7, 8, 9,
  m, coma y punto para caminar (también por el mapa), Alt+1 y Alt+2 la vida y
  la energía, F2 a F5 lo último de cada lista y con Mayúsculas la lista, F11
  el modo y F12 el silencio.

## Contribuir

Cómo hacer un plugin, paso a paso, y cómo ayudarse de una IA:
[plugins.es.md](https://github.com/midnattsol/muddie/blob/main/docs/plugins.es.md),
con cada función en
[scripting.es.md](https://github.com/midnattsol/muddie/blob/main/docs/scripting.es.md).


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
