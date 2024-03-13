import flask
from time import sleep
import requests

app = flask.Flask(__name__)


def context_get_headers(headers):
    header_names = [
        # Specification for context propagation headers
        'X-B3-Traceid',
        'X-B3-Spanid',
        'X-B3-Parentspanid',
        'X-B3-Sampled',
        'X-B3-flags',
        'X-Request-Id',
    ]
    trace_headers = {}

    for name in header_names:
        if name in headers:
            trace_headers[name] = headers[name]
    return trace_headers

@app.route('/no-header-forwarding')
def no_forwarding():
    # Simulate some work
    sleep(0.1)
    response = requests.get('http://app2:9080')
    # Simulate some work
    sleep(0.1)
    return flask.Response(response.text)

@app.route('/header-forwarding')
def forwarding():
    # Capture headers from the incoming request
    headers = context_get_headers(dict(flask.request.headers))
    # Simulate some work
    sleep(0.1)
    response = requests.get('http://app2:9080', headers=headers)
    # Simulate some work
    sleep(0.1)
    return flask.Response(response.text)

if __name__ == "__main__":
    app.run()