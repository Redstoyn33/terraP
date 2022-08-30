import net

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

fn len_to_bytes(i i16) []u8 {
	mut temp := i
	mut buf := []u8{cap: int(i)}
	buf << u8(temp)
	buf << u8(temp >>> 8)
	return buf
}

type PacC2S = PConnectRequest | u8

struct PConnectRequest {
	version string
}

fn pacc2s_from_packet(p Packet) PacC2S {
	match p.typ {
		1 {
			return PConnectRequest{p.data[1..].bytestr()}
		}
		else {
			panic('unknown packet')
		}
	}
}

type PacS2C = PDisconnect | PSetUserSlot

struct PDisconnect {
	reason string
}

struct PSetUserSlot {
	id u8
}

fn pacs2c_to_bytes(p PacS2C) []u8 {
	match p {
		PDisconnect {
			s_bytes := p.reason.bytes()
			mut buf := len_to_bytes(i16(5 + s_bytes.len))
			buf << 2
			buf << 0
			buf << u8(s_bytes.len)
			buf << s_bytes
			return buf
		}
		else {
			return []
		}
	}
}
