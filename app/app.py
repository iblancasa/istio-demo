import flask
from time import sleep
import requests


app = flask.Flask(__name__)


def context_get_headers(headers):
    header_names = [
        "x-b3-traceid",
        "x-b3-spanid",
        "x-b3-parentspanid",
        "x-b3-sampled",
        "x-b3-flags",
        "x-request-id",
    ]
    trace_headers = {}

    for name in header_names:
        if name in headers:
            trace_headers[name] = headers[name]
    return trace_headers



@app.route('/')
def hello():
    # Capture headers from the incoming request
    headers = dict(flask.request.headers)
    sleep(1) # Simulate work
    response = requests.get('http://app2:9080', headers=context_get_headers(headers))
    sleep(0.5)  # Simulate work
    return flask.Response(response.text)

if __name__ == "__main__":
    app.run()