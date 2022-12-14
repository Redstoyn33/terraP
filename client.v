import net
import time { ticks }

struct Client {
	out chan PacS2C = chan PacS2C{cap: 5}
	inp chan PacC2S = chan PacC2S{cap: 5}
mut:
	con           &net.TcpConn
	last_responce i64
	close         bool
	player        Player
}

fn (mut c Client) handler() {
	c.last_responce = ticks()
	for {
		select {
			op := <-c.out {
				c.con.write(pacs2c_to_bytes(op)) or { return }
			}
			else {}
		}
		p := read_packet(mut c.con) or {
			now := ticks()
			if now - c.last_responce < close_time {
				c.close = true
				c.con.close() or { return }
				return
			}
			c.last_responce = ticks()
			continue
		}

		c.inp <- pacc2s_from_packet(p) or { continue }
	}
}

const close_time = 20

struct Player {
mut:
	info P4PlayerInfo
}
