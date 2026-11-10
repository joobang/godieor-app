#!/usr/bin/env python3
"""LAN-scoped HTTPS proxy to GODIEOR's loopback-only development API."""
import argparse
import http.client
import http.server
import ipaddress
import os
import ssl

MAX_BODY = 2 * 1024 * 1024


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        # Never print paths, tokens, request bodies, or response headers.
        pass

    def do_GET(self):
        self.forward()

    def do_POST(self):
        self.forward()

    def do_PUT(self):
        self.forward()

    def do_DELETE(self):
        self.forward()

    def do_PATCH(self):
        self.forward()

    def forward(self):
        size_str = self.headers.get('Content-Length', '0')
        try:
            size = int(size_str)
            if size < 0 or size > MAX_BODY or self.headers.get('Transfer-Encoding'):
                raise ValueError()
        except ValueError:
            self.send_error(413)
            return
        body = self.rfile.read(size) if size else None
        headers = {k: v for k, v in self.headers.items()
                   if k.lower() not in ('host', 'connection', 'content-length', 'transfer-encoding', 'accept-encoding')}
        headers['Host'] = '127.0.0.1:3000'
        headers['Connection'] = 'close'
        if body is not None:
            headers['Content-Length'] = str(len(body))
        conn = http.client.HTTPConnection('127.0.0.1', 3000, timeout=15)
        try:
            conn.request(self.command, self.path, body=body, headers=headers)
            response = conn.getresponse()
            data = response.read(MAX_BODY + 1)
            if len(data) > MAX_BODY:
                self.send_error(502)
                return
            self.send_response(response.status)
            for k, v in response.getheaders():
                if k.lower() not in ('connection', 'transfer-encoding', 'content-length', 'content-encoding'):
                    self.send_header(k, v)
            self.send_header('Content-Length', str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        except (OSError, http.client.HTTPException):
            self.send_error(502, 'Local backend unavailable')
        finally:
            conn.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ip', required=True, help='Mac LAN IPv4 address; proxy binds only here')
    parser.add_argument('--cert', required=True)
    parser.add_argument('--key', required=True)
    parser.add_argument('--port', type=int, default=3443)
    args = parser.parse_args()
    ip = ipaddress.ip_address(args.ip)
    if ip.version != 4 or not ip.is_private or ip.is_loopback or ip.is_link_local:
        parser.error('--ip must be a private, non-loopback LAN IPv4 address')
    if not 1024 <= args.port <= 65535:
        parser.error('port must be between 1024 and 65535')
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.load_cert_chain(args.cert, args.key)
    server = http.server.ThreadingHTTPServer((args.ip, args.port), Handler)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    print(f'Local HTTPS: https://{args.ip}:{args.port}/v1 (Ctrl+C to stop)', flush=True)
    server.serve_forever()


if __name__ == '__main__':
    main()
