"""Add a local chat page to openTPU's existing model server."""

from pathlib import Path
from urllib.parse import urlsplit

from opentpu.serve import api

PAGE = Path(__file__).with_name("index.html")
make_api_handler = api.make_handler


def make_chat_handler(server):
    class ChatHandler(make_api_handler(server)):
        def parse_request(self):
            if not super().parse_request():
                return False
            port = self.server.server_address[1]
            host = self.headers.get("Host", "").lower()
            origin = self.headers.get("Origin")
            if host not in (f"127.0.0.1:{port}", f"localhost:{port}") or (
                self.command == "POST" and origin and origin != f"http://{host}"
            ):
                self.close_connection = True
                self.send_error(403, "This service only accepts local requests.")
                return False
            return True

        def do_GET(self):
            path = urlsplit(self.path).path.rstrip("/")
            if path in ("", "/chat"):
                self._send(200, PAGE.read_bytes(), "text/html; charset=utf-8")
                return
            super().do_GET()

    return ChatHandler


if __name__ == "__main__":
    api.make_handler = make_chat_handler
    raise SystemExit(api.main())
