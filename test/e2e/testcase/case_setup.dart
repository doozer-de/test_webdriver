import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

Future<HttpServer> setupServer() => io.serve(
    const shelf.Pipeline().addHandler((_) => new shelf.Response(200,
        headers: {'Content-Type': 'text/html'}, body: '''
  <html>
    <body>
      <div class="hello">Hello</div>
      <div class="test2">Test 2</div>
      <div class="invalid-po">
        <div class="exists">Hello2</div>
      </div>
    </body>
  </html>
  ''')),
    'localhost',
    0);

Future<Process> setupChromeDriver() => Process.start('chromedriver', []);