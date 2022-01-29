from flask import Flask
import socket

app = Flask(__name__)

@app.after_request
def apply_caching(response):
    response.headers["X-Upstream-App"] = socket.gethostname()
    return response

@app.route('/')
def hello():
    return "<h1>Hello, Datadome!</h1>"

@app.route('/health')
def health():
    return "ok"

if __name__ == "__main__":
    app.run(debug=True)
