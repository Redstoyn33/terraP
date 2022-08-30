import time

const (
	server_update_rate = time.second / 4
	client_update_rate = time.second / 4
)

struct Server {
	new_client chan &Client = chan &Client{cap: 1}
mut:
	clients map[u8]&Client = map[u8]&Client{}
	ids     u8
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
		for id, mut c in s.clients {
			if c.close {
				s.clients.delete(id)
				continue
			}
			select {
				p := <-c.inp {
					match p {
						P1ConnectRequest {
							c.out <- P3SetUserSlot{id}
						}
						P4PlayerInfo {
							c.player.info = p
						}
					}
				}
				else {}
			}
		}
		// тики сервера
		time.sleep(server_update_rate)
	}
}
