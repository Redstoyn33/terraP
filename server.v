import time

const (
	server_update_rate = time.second/4
	client_update_rate = time.second/4
)

struct Server {
	new_client chan &Client = chan &Client{cap: 1}
mut:
	clients map[u8]&Client = map[u8]&Client{}
	ids u8
}

fn (mut s Server) work() {
	for {
		select {
			mut new_c := <-s.new_client {
				if s.ids in s.clients {
					continue
				}
				new_c.con.set_read_timeout(client_update_rate)
				s.clients[s.ids] = new_c
				go new_c.handler()
				s.ids++
			}
			else {}
		}
		for id, c in s.clients {
			if c.close {
				s.clients.delete(id)
				continue
			}
			select {
				p := <-c.inp {
					if p is PConnectRequest {
						c.out <- PDisconnect{'you num $id, len $s.clients.len'}
					}
				}
				else {}
			}
		}
		// тики сервера
		time.sleep(server_update_rate)
	}
}
