import flask
from time import sleep
import requests


app = flask.Flask(__name__)

@app.route('/')
def hello():
    # Capture headers from the incoming request
    headers = dict(flask.request.headers)
    sleep(1) # Simulate work
    response = requests.get('http://app2:9080', headers=headers)
    sleep(0.5)  # Simulate work
    return flask.Response(response.text)

if __name__ == "__main__":
    app.run()