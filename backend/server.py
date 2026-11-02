"""Local HTTP service with authenticated API, detector, and browser console."""
import argparse
import json
import logging
import os
import sqlite3
import threading
import time
from collections import defaultdict, deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse
from .domain import Problem, Store


def make_server(store, host='127.0.0.1', port=8080, web=None):
    attempts = defaultdict(deque)
    lock = threading.Lock()
    web = Path(web).resolve() if web else Path(__file__).with_name('web').resolve()

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            logging.info('%s %s', self.command, self.path.split('?')[0])

        def send_headers(self, code, content_type='application/json', length=0):
            self.send_response(code)
            self.send_header('Content-Type',content_type)
            self.send_header('Content-Length',str(length))
            self.send_header('Cache-Control','no-store')
            self.send_header('X-Content-Type-Options','nosniff')
            self.send_header('Referrer-Policy','no-referrer')
            origin = self.headers.get('Origin')
            if origin in ('http://localhost:3000','http://127.0.0.1:3000'):
                self.send_header('Access-Control-Allow-Origin',origin)
                self.send_header('Vary','Origin')
                self.send_header('Access-Control-Allow-Headers','Authorization, Content-Type')
                self.send_header('Access-Control-Allow-Methods','GET, POST, OPTIONS')
            self.end_headers()

        def reply(self, code, data):
            body = json.dumps(data).encode()
            self.send_headers(code,length=len(body))
            self.wfile.write(body)

        def do_OPTIONS(self):
            self.send_headers(204)

        def do_GET(self):
            self.dispatch()

        def do_POST(self):
            self.dispatch()

        def dispatch(self):
            try:
                parsed = urlparse(self.path)
                path = parsed.path
                if self.command == 'GET' and path == '/api/health':
                    return self.reply(200,{'ok':True,'demo':store.demo})
                if not path.startswith('/api/'):
                    if self.command != 'GET':
                        raise Problem('Not found.',404)
                    import mimetypes
                    target = (web / (path.lstrip('/') or 'index.html')).resolve()
                    if not target.is_relative_to(web) or not target.is_file():
                        raise Problem('File not found.',404)
                    body = target.read_bytes()
                    self.send_headers(200,mimetypes.guess_type(target.name)[0] or 'application/octet-stream',len(body))
                    self.wfile.write(body)
                    return
                token = self.headers.get('Authorization','').removeprefix('Bearer ')
                if self.command == 'GET' and path == '/api/state':
                    try:
                        days = int(parse_qs(parsed.query).get('days',['30'])[0])
                    except ValueError:
                        raise Problem('days must be an integer.')
                    return self.reply(200,store.snapshot(token,days))
                if self.command != 'POST':
                    raise Problem('Not found.',404)
                if self.headers.get_content_type() != 'application/json':
                    raise Problem('Content-Type must be application/json.',415)
                try:
                    length = int(self.headers.get('Content-Length','0'))
                except ValueError:
                    raise Problem('Invalid request length.')
                if not 0 < length <= 16384:
                    raise Problem('JSON body must be 1–16384 bytes.',413)
                try:
                    data = json.loads(self.rfile.read(length))
                except (ValueError,UnicodeDecodeError):
                    raise Problem('Invalid JSON.')
                if not isinstance(data,dict):
                    raise Problem('Expected a JSON object.')
                if path == '/api/login':
                    with lock:
                        queue = attempts[self.client_address[0]]
                        while queue and queue[0] < time.time()-60:
                            queue.popleft()
                        if len(queue) >= 15:
                            raise Problem('Too many sign-in attempts. Wait one minute.',429)
                        queue.append(time.time())
                    return self.reply(200,store.login(data))
                return self.reply(200,store.mutate(token,path.removeprefix('/api/'),data))
            except Problem as error:
                self.reply(error.status,{'error':str(error)})
            except sqlite3.IntegrityError:
                self.reply(409,{'error':'Duplicate record or conflicting assignment. Refresh and check your input.'})
            except Exception:
                logging.exception('Request failed')
                self.reply(500,{'error':'Internal server error. Check server log.'})

    return ThreadingHTTPServer((host,port),Handler)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--db',default=os.getenv('SMARTSWEEP_DB','data/smartsweep.db'))
    parser.add_argument('--demo',action='store_true')
    parser.add_argument('--seed',action='store_true')
    parser.add_argument('--port',type=int,default=8080)
    parser.add_argument('--web',help='Optional compiled Flutter build/web directory')
    parser.add_argument('--delay-minutes',type=int,default=15)
    parser.add_argument('--recurrence',type=int,default=3)
    parser.add_argument('--create-supervisor',metavar='EMAIL')
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(levelname)s %(message)s')
    store = Store(args.db,args.demo,args.delay_minutes,args.recurrence)
    if args.seed or args.create_supervisor:
        password = os.getenv('SMARTSWEEP_PASSWORD')
        if not password:
            import getpass
            password = getpass.getpass('New account password (12+ characters): ')
        if args.seed:
            store.seed(password)
        else:
            store.create_user(args.create_supervisor,password,'supervisor')
        print('Accounts saved. Password was not logged.')
    server = make_server(store,port=args.port,web=args.web)
    stop = threading.Event()

    def detector():
        while not stop.wait(5):
            try:
                store.tick()
            except Exception:
                logging.exception('Detector failed')

    thread = threading.Thread(target=detector,daemon=True)
    thread.start()
    logging.info('SmartSweep at http://127.0.0.1:%s (demo=%s)',args.port,args.demo)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        stop.set()
        server.server_close()
        thread.join(timeout=6)


if __name__ == '__main__':
    main()
