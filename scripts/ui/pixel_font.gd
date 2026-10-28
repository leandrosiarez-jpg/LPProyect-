class_name PixelFont
extends RefCounted
## Tipografía pixel propia de GummyWars.
## El original usa dos atlas de imagen de 144x112 (relleno blanco que se tiñe con
## color de texto y borde/sombra negro). Los atlas de caracteres
## están embebidos acá en hexadecimal.
## Glifos de 9x14 en 16 columnas; alto de línea 11, separación 2, espacio 3.
## PixelLabel replica PixelFont.Bind(label): Text, color, transparencia, alineación,
## texto escalado o de tamaño fijo, ajuste de línea y <font color="#hex">.

const CW := 9
const CH := 14
const COLS := 16
const LINE_H := 11
const LINE_GAP := 2
const SPACE := 3

const ORDER := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz.,:;!¡?¿-—+/()'\"%$#*=_<>[]·★►◄✓&@º→…×♥íÁÉÍÓÚÑÜáéóúñü"
const WIDTHS := "555555553555555555555555555355555555555554553443555555545555551212115547552213555555442215445553555535535555555555"

## Letras que la tipografía no tiene: se dibujan con su letra base
const TRANSLIT_GROUPS := {
	"a": "àâãäåăắằẳẵặấầẩẫậạả", "e": "èêëẹẻẽếềểễệ", "i": "ìîïịỉĩ", "o": "òôõöơọỏốồổỗộớờởỡợ",
	"u": "ùûưụủũứừửữự", "y": "ýỳỵỷỹÿ", "d": "đ", "c": "ç",
	"A": "ÀÂÃÄÅĂẮẰẲẴẶẤẦẨẪẬẠẢ", "E": "ÈÊËẸẺẼẾỀỂỄỆ", "I": "ÌÎÏỊỈĨ", "O": "ÒÔÕÖƠỌỎỐỒỔỖỘỚỜỞỠỢ",
	"U": "ÙÛƯỤỦŨỨỪỬỮỰ", "Y": "ÝỲỴỶỸ", "D": "Đ", "C": "Ç",
}

## Atlas de relleno (FILL): 112 filas de 144 bits
const FILL_HEX := """
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
383c0e0f07c3e0e088700e1108044220e0f0
4422110884020110882004120806c2211088
442210088402010088200414080543211088
7c3c10088783c170f8200418080542a110f0
442210088402011088202414080442611080
442211088402011088202412080442211080
443c0e0f07c200f0887018110f844220e080
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
383c0f0f8442211088443e0e040383c020f8
4422100204422110884402110c0440206080
44221002044221105028041304004020a0f0
443c0e020442215020100815040081c12008
54280102044221505010101904010021f008
482401020441415088102011040200202088
34221e02038080a088103e0e0e07c3c02070
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
183e0e070002000008000c000802004100c0
200211088002000008001000080000010040
400411088383c0e078383c0f0f0600c12040
78080e078042210088441011088200414040
4410110083c22100887c1011088200418040
44101101044221108840100f088200414040
38100e0603c3c0e0783810010887024120e0
00000000000000000000000e000001800000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000040000000000000000000
000000000000000040000000000000000000
683c0e0f03c2c0f0f0442211088443e00000
542211088443210040442211050440400000
54221108844200e040442215020440800000
5422110f03c20010404c14150503c1000040
54220e08004201e03034080a088043e10040
000000080040000000000000000380000080
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000010080380800000000208080402818020
000010000440000000100410040402819078
4010100800408000001004100400000020a0
00001008008101e0fe7c0810040000004070
000010080102000000101010040000008028
4010000800022000001010100400000130f0
002010080101c00000002008080000003020
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
2800000000820180c000081001000180e040
282a000001010100400008180300424110a0
7c1c1f000200810040003e1c070082817040
283e00000400410040401c1e0f0501015000
7c1c1f00020081004000141c070202a170e0
282a00000101010040002218030002410000
2800000f80820180c0000010010001a0e000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
00000000000040202008040d000000000000
000000000000804040100812050000000000
000000000101c1f0e0382211088080402010
100000050202210040442211088100804020
0800110f8602210040442219088381c0e088
7c000a0f8203e1e040442215088042211088
0800040702022100404422130883c3e11088
10000a020202210040442211088442011098
002a1100070221f0e0381c110703c1c0e068
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
340000000000000000000000000000000000
481400000000000000000000000000000000
782200000000000000000000000000000000
442200000000000000000000000000000000
442200000000000000000000000000000000
442600000000000000000000000000000000
441a00000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
"""

## Atlas de borde y sombra (BACK)
const BACK_HEX := """
000000000000000000000000000000000000
000000000000000000000000000000000000
7c7e1f1f8fe7f1f1dcf81f3b9c0ee771f1f8
fe7f3f9fcfe7f3f9dcf81f3f9c0fe773f9fc
fe7f3f9fcfe7f3f9dcf81f3f9c0fe7f3f9fc
fe7f3f9fcfe7f3f9fcf81f3f9c0fe7f3f9fc
fe7f3b9dcfc7e3f9fc707e3f1c0fe7f3b9fc
fe7f3b9dcfc7e3f9fc707e3f1c0fe7f3b9fc
fe7f3f9fcfe7e3f9fcf87e3f9fcfe7f3f9f8
ee7f3f9fcfe703f9dcf87e3f9fcee7f3f9c0
ee7f3f9fcfe703f9dcf87e3f9fcee773f9c0
ee7e1f1f8fe701f9dcf83c3b9fcee771f1c0
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
7c7e1f9fcee773b9dcee7f1f0e07c7e071fc
fe7f3f9fcee773b9dcee7f3f9e0fe7f0f1fc
fe7f3f9fcee773b9fcfe7f3f9e0fe7f1f1fc
fe7f3f9fcee773f9fcfe7f3f9e0fe7f3f1fc
fe7f3f870ee773f9fcfe3f3f9e0fe3f3f9fc
fe7f3f870ee7f3f9fc7c7e3f8e07e3f3f9fc
fe7f3f870fe7f3f9fc387f3f9f0fe7f3f9fc
fe7f3f870fe7f3f9fc387f3f9f0fe7f3f9fc
fe7f3f870fe3e3f9dc387f3f9f0fe7f071fc
7e773f0707c1c1f1dc387f1f1f0fe7e070f8
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
3c7f1f0f800700001c001e001c0700e381e0
7c7f3f9fc00700001c003e001c0700e381e0
fc7f3f9fc7c7e1f0fc7c7e1f9f8f01e3f1e0
fc7f3f9fc7e7f3f1fcfe7e3f9fcf01e3f1e0
fe3f3f9fc7e7f3f1fcfe7e3f9fcf01e3f0e0
fe3e3f9fcfe7f3f9fcfe7e3f9fcf01e3f0e0
fe3c3f8fcfe7f3f9fcfe383f9dcf87e3f1f0
fe383f8fcfe7f3f9fcfe383f9dcf87e3f1f0
fe383f8f8fe7f3f9fcfc381f9dcf87e3f1f0
7c381f0f07e7e1f0fc7c381f9dcf87e3f1f0
00000000000000000000001f000003c00000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
0000000000000000e0000000000000000000
0000000000000000e0000000000000000000
fc7e1f1f87e7e1f9f8ee773b9dcee7f00000
fe7f3f9fcfe7f3f9f8ee773b9fcee7f00000
fe7f3f9fcfe7f3f9f8ee773f9fcee7f00000
fe7f3f9fcfe7f3f9f8fe7f3f9fcfe7f000e0
fe773f9fcfe7f3f8f8fe7f3f9fcfe7f380e0
fe773f9fcfe703f8f8fe7f3f9fcfe7f381e0
fe773f9f87e703f8f8fe3e3f9fc7e7f381e0
fe771f1c00e703f0787e1c1f1dc7e7f381e0
0000001c00e00000000000000007c00001c0
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
0000381c07c1c0000000071c1c0e07c3c070
0000381c0fe1c00000380f3c1e0e07c3f8fc
e038381c0fe1c00000380f3c1e0e07c3f9fc
e038381c0fe3c3f1fffe1f3c1e0e07c3f9fc
e038381c0fe7c3f1fffe3e380e0e07c3f9fc
e038381c03e7f3f1fffe3e380e000003f9fc
e078381c03c7f3f1fffe7c3c1e000003f9fc
e078381c0387f0000038783c1e000003f9fc
e078381c0387f0000038783c1e000003f9f8
0070381c0383e0000000701c1c0000007870
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
7c00000001c703c1e0001c38038003c1f0e0
7c7f000003c783c1e0001c3c0780e7e3f9f0
fe7f3f8007c7c3c1e0007f3e0f81e7e3f9f0
fe7f3f800fc7e3c1e0e07f3f1f8fe7e3f9f0
fe7f3f800f83e380e0e07f3f1f8fe7f3f9f0
fe7f3f800f83e380e0e07f3f1f8fc7f3f9f0
fe7f3f9fcfc7e3c1e0e07f3f1f8f87f3f9f0
fe7f3f9fc7c7c3c1e0007f3e0f8707f3f9f0
7c7f001fc3c783c1e000773c078007f3f000
7c00001fc1c703c1e0000038038003f1f000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000e070701c0e1f800000000000
000000000001e0f0f03c1e3f8f8000000000
000000000383e3f9f07c7f3f9fc1c0e07038
3800000f8787f3f9f0fe7f3f9fc3c1e0f078
3c003b9fcf87f3f9f0fe7f3f9fc7c3e1f1fc
fe003f9fcf87f3f9f0fe773f9dc7e7f3f9fc
fe003f9fcf07f3f0e0ee773f9dc7e7f3f9fc
fe003f9fcf07f3f0e0ee773f9dcfe7f3f9fc
fe7f3f9fcf87f3f9f0fe7f3f9fcfe7f3f9fc
3c7f3f8f8f8773f9f0fe7f3f9fcfe7f3f9fc
387f3f870f8773f9f0fe7f3b9fcfe7e3f9fc
007f3b800f8773f9f07c3e3b8f87e3e1f0fc
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
7e0000000000000000000000000000000000
fe3e00000000000000000000000000000000
fe7f00000000000000000000000000000000
fe7f00000000000000000000000000000000
fe7f00000000000000000000000000000000
fe7f00000000000000000000000000000000
ee7f00000000000000000000000000000000
ee7f00000000000000000000000000000000
ee7f00000000000000000000000000000000
ee3f00000000000000000000000000000000
000000000000000000000000000000000000
000000000000000000000000000000000000
"""

static var _glyphs := {}
static var _fill: Texture2D
static var _back: Texture2D


static func _init_tables() -> void:
	if not _glyphs.is_empty():
		return
	for i in ORDER.length():
		_glyphs[ORDER[i]] = [i, int(WIDTHS[i])]
	for base in TRANSLIT_GROUPS:
		var chars: String = TRANSLIT_GROUPS[base]
		for ch in chars:
			if not _glyphs.has(ch) and _glyphs.has(base):
				_glyphs[ch] = _glyphs[base]


static func _atlas(hex: String, color: Color) -> Texture2D:
	var img := Image.create(COLS * CW, 112, false, Image.FORMAT_RGBA8)
	var rows := hex.strip_edges().split("\n")
	for y in rows.size():
		var row: String = rows[y].strip_edges()
		for k in row.length():
			var v := ("0x" + row[k]).hex_to_int()
			for b in 4:
				if v & (8 >> b):
					img.set_pixel(k * 4 + b, y, color)
	return ImageTexture.create_from_image(img)


static func fill_texture() -> Texture2D:
	if _fill == null:
		_fill = _atlas(FILL_HEX, Color.WHITE)
	return _fill


static func back_texture() -> Texture2D:
	if _back == null:
		_back = _atlas(BACK_HEX, Color.BLACK)
	return _back


static var _font: FontFile


## Fuente de mapa de bits (FontFile) con el borde negro y el relleno blanco del atlas
## combinados: draw_string(..., color) tiñe el relleno y deja el borde negro, como el
## original. Tamaño nativo 14 (un píxel del atlas por unidad); escala con font_size.
static func font() -> FontFile:
	if _font:
		return _font
	_init_tables()
	var img := Image.create(COLS * CW, 112, false, Image.FORMAT_RGBA8)
	for pass_i in 2:
		var hex: String = BACK_HEX if pass_i == 0 else FILL_HEX
		var c := Color.BLACK if pass_i == 0 else Color.WHITE
		var rows := hex.strip_edges().split("\n")
		for y in rows.size():
			var row: String = rows[y].strip_edges()
			for k in row.length():
				var v := ("0x" + row[k]).hex_to_int()
				for b in 4:
					if v & (8 >> b):
						img.set_pixel(k * 4 + b, y, c)
	var f := FontFile.new()
	var sz := Vector2i(CH, 0)
	f.fixed_size = CH
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
	f.set_cache_ascent(0, CH, 10.0)
	f.set_cache_descent(0, CH, 4.0)
	f.set_texture_image(0, sz, 0, img)
	var chars := ORDER + " "
	for base in TRANSLIT_GROUPS:
		chars += TRANSLIT_GROUPS[base]
	for ch in chars:
		var code := ch.unicode_at(0)
		if ch == " ":
			f.set_glyph_advance(0, CH, code, Vector2(SPACE + 1, 0))
			continue
		var g := glyph_of(ch)
		var idx: int = g[0]
		f.set_glyph_advance(0, CH, code, Vector2(int(g[1]) + 1, 0))
		f.set_glyph_offset(0, sz, code, Vector2(-1, -10))
		f.set_glyph_size(0, sz, code, Vector2(CW, CH))
		f.set_glyph_uv_rect(0, sz, code, Rect2((idx % COLS) * CW, (idx / COLS) * CH, CW, CH))
		f.set_glyph_texture_idx(0, sz, code, 0)
	_font = f
	return f


static func glyph_of(ch: String) -> Array:
	_init_tables()
	if _glyphs.has(ch):
		return _glyphs[ch]
	var up := ch.to_upper()
	if _glyphs.has(up):
		return _glyphs[up]
	return _glyphs["?"]


static func advance(ch: String) -> int:
	if ch == " ":
		return SPACE + 1
	return int(glyph_of(ch)[1]) + 1


## [[caracter, Color o null], ...]. Con rich, entiende <font color="#hex"> y </font>
## e ignora el resto de las etiquetas.
static func parse(text: String, rich: bool) -> Array:
	var out := []
	var stack := []
	var i := 0
	var n := text.length()
	while i < n:
		var c := text[i]
		if rich and c == "<":
			var close := text.find(">", i)
			if close >= 0:
				var tag := text.substr(i + 1, close - i - 1)
				var re := RegEx.create_from_string("^font\\s+color\\s*=\\s*\"#?([0-9a-fA-F]{6})\"")
				var m := re.search(tag)
				if m:
					stack.append(Color.html(m.get_string(1)))
				elif tag == "/font":
					stack.pop_back()
				i = close + 1
				continue
		out.append([c, stack.back() if not stack.is_empty() else null])
		i += 1
	return out


## Líneas {chars, width} con ajuste por palabra si max_width > 0 (en px de fuente).
static func layout(chars: Array, max_width: float = -1.0) -> Array:
	var lines := []
	var line := []
	var width := 0
	var word_start := -1
	var width_at_word_start := 0
	for item in chars:
		var ch: String = item[0]
		if ch == "\n":
			lines.append({"chars": line, "width": width})
			line = []
			width = 0
			word_start = -1
			continue
		var adv := advance(ch)
		if ch == " ":
			word_start = -1
		elif word_start < 0:
			word_start = line.size()
			width_at_word_start = width
		if max_width > 0.0 and width + adv - 1 > max_width and line.size() > 0 and ch != " ":
			if word_start > 0:
				var moved := line.slice(word_start)
				line = line.slice(0, word_start)
				var trimmed := width_at_word_start
				while line.size() > 0 and line.back()[0] == " ":
					trimmed -= advance(" ")
					line.pop_back()
				lines.append({"chars": line, "width": trimmed})
				line = moved
				width = 0
				for mv in moved:
					width += advance(mv[0])
				word_start = 0
				width_at_word_start = 0
			else:
				lines.append({"chars": line, "width": width})
				line = []
				width = 0
				word_start = 0
				width_at_word_start = 0
		line.append(item)
		width += adv
	lines.append({"chars": line, "width": width})
	for l in lines:
		l["width"] = maxi(0, int(l["width"]) - 1)
	return lines


static func block_height(n_lines: int) -> int:
	return n_lines * LINE_H + (n_lines - 1) * LINE_GAP


## Medida de un texto en píxeles para una escala dada
static func measure(text: String, scale: float, max_width: float = -1.0, rich: bool = false) -> Vector2:
	var ls := layout(parse(text, rich), floorf(max_width / scale) if max_width > 0.0 else -1.0)
	var w := 0
	for l in ls:
		w = maxi(w, int(l["width"]))
	return Vector2(w * scale, block_height(ls.size()) * scale)


## Escala con TextSize (TextScaled = false)
static func scale_for_size(text_size: float) -> float:
	return maxf(1.0, floorf(text_size / 8.0 + 0.5))


## Etiqueta con la tipografía pixel.
class PixelLabel extends Control:
	## 0 = izquierda/arriba, 1 = centro, 2 = derecha/abajo
	var text := "":
		set(v):
			if v != text:
				text = v
				_dirty = true
				queue_redraw()
	var color := Color(1, 1, 1):
		set(v):
			color = v
			queue_redraw()
	var transparency := 0.0:
		set(v):
			transparency = v
			queue_redraw()
	var x_align := 1:
		set(v):
			x_align = v
			_dirty = true
			queue_redraw()
	var y_align := 1:
		set(v):
			y_align = v
			_dirty = true
			queue_redraw()
	var scaled := true:
		set(v):
			scaled = v
			_dirty = true
			queue_redraw()
	var text_size := 14.0:
		set(v):
			text_size = v
			_dirty = true
			queue_redraw()
	var wrapped := false:
		set(v):
			wrapped = v
			_dirty = true
			queue_redraw()
	var rich := false:
		set(v):
			rich = v
			_dirty = true
			queue_redraw()
	var no_outline := false:
		set(v):
			no_outline = v
			queue_redraw()

	var _dirty := true
	var _box := Vector2.ZERO
	var _scale := 1.0
	var _lines: Array = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		resized.connect(func():
			pivot_offset = size * 0.5
			if (size - _box).length() > 1.0:
				_dirty = true
				queue_redraw())

	func _measure(chars: Array, s: float) -> Array:
		var ls := PixelFont.layout(chars, maxf(1.0, floorf(size.x / s)) if wrapped else -1.0)
		var w := 0
		for l in ls:
			w = maxi(w, int(l["width"]))
		return [ls, w * s, PixelFont.block_height(ls.size()) * s]

	func _relayout() -> void:
		_dirty = false
		_box = size
		var chars := PixelFont.parse(text, rich)
		var box := size
		if scaled:
			_lines = []
			var s := 14.0
			var found := false
			while s >= 1.0:
				var m := _measure(chars, s)
				if m[1] <= box.x + 0.5 and m[2] <= box.y + 0.5:
					_scale = s
					_lines = m[0]
					found = true
					break
				s -= 0.5
			if not found:
				var m1 := _measure(chars, 1.0)
				_scale = maxf(0.4, minf(box.x / maxf(m1[1], 1.0), box.y / maxf(m1[2], 1.0)))
				_lines = m1[0]
		else:
			_scale = PixelFont.scale_for_size(text_size)
			var m := _measure(chars, _scale)
			while _scale > 1.0 and box.y > 0.0 and m[2] > box.y + 2.0:
				_scale -= 1.0
				m = _measure(chars, _scale)
			_lines = m[0]

	## Alto que ocupa el texto (para AutomaticSize Y)
	func content_height() -> float:
		if _dirty:
			_relayout()
		return PixelFont.block_height(_lines.size()) * _scale

	func _draw() -> void:
		if text == "":
			return
		if _dirty:
			_relayout()
		var a := 1.0 - transparency
		if a <= 0.0:
			return
		var lum := color.r * 0.3 + color.g * 0.59 + color.b * 0.11
		var show_back := not (no_outline or lum < 0.28)
		var sc := _scale
		var total_h := PixelFont.block_height(_lines.size()) * sc
		var y0 := 0.0
		if y_align == 1:
			y0 = (size.y - total_h) / 2.0
		elif y_align == 2:
			y0 = size.y - total_h
		var quads := []
		for li in _lines.size():
			var line: Dictionary = _lines[li]
			var lw: float = line["width"] * sc
			var x := 0.0
			if x_align == 1:
				x = (size.x - lw) / 2.0
			elif x_align == 2:
				x = size.x - lw
			var y := y0 + li * (PixelFont.LINE_H + PixelFont.LINE_GAP) * sc
			for item in line["chars"]:
				var ch: String = item[0]
				if ch != " ":
					var g := PixelFont.glyph_of(ch)
					var idx: int = g[0]
					var src := Rect2((idx % PixelFont.COLS) * PixelFont.CW, (idx / PixelFont.COLS) * PixelFont.CH, PixelFont.CW, PixelFont.CH)
					var dst := Rect2(floorf(x - sc + 0.5), floorf(y - sc + 0.5), PixelFont.CW * sc, PixelFont.CH * sc)
					quads.append([src, dst, item[1]])
				x += PixelFont.advance(ch) * sc
		if show_back:
			var bt := PixelFont.back_texture()
			for q in quads:
				draw_texture_rect_region(bt, q[1], q[0], Color(1, 1, 1, a))
		var ft := PixelFont.fill_texture()
		for q in quads:
			var c: Color = q[2] if q[2] != null else color
			draw_texture_rect_region(ft, q[1], q[0], Color(c, a))
