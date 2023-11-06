from flask import Flask, request, Response
from time import sleep


app = Flask(__name__)

@app.route('/')
def bye():
    # Simulate some work
    sleep(2)
    return Response("bye")

if __name__ == "__main__":
    app.run(debug=False)