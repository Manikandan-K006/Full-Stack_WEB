import http.server
import os

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

if __name__ == '__main__':
    os.chdir('/home/mani-arch/Desktop/FSD lab/fullstack-web-lab/frontend/build/web')
    server = http.server.HTTPServer(('0.0.0.0', 8080), NoCacheHandler)
    print('Serving on http://localhost:8080')
    server.serve_forever()