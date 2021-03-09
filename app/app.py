
import os, json, logging
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/')
def index():
    return jsonify(msg='DevOps Challenge App')

@app.route('/health')
def health():
    return jsonify({'success':True})

@app.route('/code')
def code():
    if "Code" in os.environ:
        return jsonify({'Code': os.environ['Code']})
    else:
        return jsonify({'Code': 'You forgot to use env ...'})

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    app.run(host='0.0.0.0', port=8008)