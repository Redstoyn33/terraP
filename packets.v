import net

struct Color {
	r u8
	g u8
	b u8
}

struct Packet {
	typ  u8
	data []u8
}

fn read_packet(mut c net.TcpConn) ?Packet {
	mut buf := []u8{len: 3}
	c.read(mut buf) or { return none }
	len := len_from_bytes(buf)
	typ := buf[2]
	if len != 1 {
		buf = []u8{len: int(len) - 3}
		c.read(mut buf) or { return none }
		return Packet{typ, buf}
	}
	return none
}

fn len_from_bytes(buf []u8) i16 {
	mut temp := i16(0)
	temp |= buf[1]
	temp <<= 8
	temp |= buf[0]
	return temp
}

struct PacWriter {
	id u8 [required]
mut:
	len i16 = 3
	buf []u8
}

fn (p PacWriter) bytes() []u8 {
	mut b := []u8{cap: int(p.len)}
	b << u8(p.len)
	b << u8(p.len >>> 8)
	b << p.id
	b << p.buf
	return b
}

fn (mut p PacWriter) write_byte(i u8) {
	p.buf << i
	p.len++
}

fn (mut p PacWriter) write_color(i Color) {
	p.buf << i.r
	p.buf << i.g
	p.buf << i.b
	p.len += 3
}

fn (mut p PacWriter) write_string(i string) {
	s_bytes := i.bytes()
	p.write_byte(u8(s_bytes.len))
	p.buf << s_bytes
	p.len += i16(s_bytes.len)
}

fn (mut p PacWriter) write_netstring(i NetString) {
	s_bytes := i.bytes()
	p.write_byte(0)
	p.write_byte(u8(s_bytes.len))
	p.buf << s_bytes
	p.len += i16(s_bytes.len)
}

fn (mut p PacWriter) write_pac<T>(i T) {
	$for f in T.fields {
		$if f.typ is u8 {
			p.write_byte(i.$(f.name))
		} $else $if f.typ is NetString {
			p.write_netstring(i.$(f.name))
		} $else $if f.typ is string {
			p.write_string(i.$(f.name))
		} $else $if f.typ is Color {
			p.write_color(i.$(f.name))
		}
	}
}

fn len_to_bytes(i i16) []u8 {
	mut temp := i
	mut buf := []u8{cap: int(i)}
	buf << u8(temp)
	buf << u8(temp >>> 8)
	return buf
}

fn pacc2s_from_bytes<T>(b []u8) T {
	mut result := T{}
	mut p := 0
	$for f in T.fields {
		$if f.typ is u8 {
			result.$(f.name) = b[p]
			p++
		} $else $if f.typ is NetString {
			len := b[p + 1]
			result.$(f.name) = b[p + 2..p + 2 + len].bytestr()
			p += 2 + len
		} $else $if f.typ is string {
			len := b[p]
			result.$(f.name) = b[p + 1..p + 1 + len].bytestr()
			p += 1 + len
		} $else $if f.typ is Color {
			result.$(f.name) = Color{b[p], b[p + 1], b[p + 2]}
			p += 3
		}
	}
	return result
}

fn pacc2s_from_packet(p Packet) ?PacC2S {
	match p.typ {
		1 {
			return pacc2s_from_bytes<P1ConnectRequest>(p.data)
		}
		4 {
			return pacc2s_from_bytes<P4PlayerInfo>(p.data)
		}
		else {
			println(p)
			return none
		}
	}
}

fn pacs2c_to_bytes(p PacS2C) []u8 {
	match p {
		P2Disconnect {
			mut wr := PacWriter{
				id: 2
			}
			wr.write_pac<P2Disconnect>(p)
			return wr.bytes()
		}
		P3SetUserSlot {
			mut wr := PacWriter{
				id: 3
			}
			wr.write_pac<P3SetUserSlot>(p)
			return wr.bytes()
		}
		P4PlayerInfo {
			mut wr := PacWriter{
				id: 4
			}
			wr.write_pac<P4PlayerInfo>(p)
			return wr.bytes()
		}
	}
}

type NetString = string

type PacC2S = P1ConnectRequest | P4PlayerInfo

type PacS2C = P2Disconnect | P3SetUserSlot | P4PlayerInfo

struct P1ConnectRequest {
	version string
}

struct P2Disconnect {
	reason NetString
}

struct P3SetUserSlot {
	id u8
}

struct P4PlayerInfo {
	id                u8
	skin_varient      u8
	hair              u8
	name              string
	hair_dye          u8
	hide_visuals      u8
	hide_visuals_2    u8
	hide_misc         u8
	hair_color        Color
	skin_color        Color
	eye_color         Color
	shirt_color       Color
	under_shirt_color Color
	pants_color       Color
	shoe_color        Color
	difficulty        u8
}
