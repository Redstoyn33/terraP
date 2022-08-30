import net

fn main() {
	mut s := &Server{}
	go s.work()
	println('Сервер запущен')
	mut listener := net.listen_tcp(.ip, ':7777')?
	println('Ожидание подключений')
	for {
		listener.wait_for_accept() or { continue }
		mut con := listener.accept() or { continue }
		s.new_client <- &Client{
			con: con
		}
	}
}
