from time import sleep
import flask

app = flask.Flask(__name__)

@app.route('/')
def bye():
    # Simulate some work
    sleep(0.15)
    return flask.Response("bye")

if __name__ == "__main__":
    app.run()
