
import logging
import os

from flask import Flask, jsonify
from elasticapm.contrib.flask import ElasticAPM

app = Flask(__name__)

app.config["ELASTIC_APM"] = {
    "SERVICE_NAME": os.getenv("ELASTIC_APM_SERVICE_NAME", "simpleapp"),
    "SECRET_TOKEN": os.getenv("ELASTIC_APM_SECRET_TOKEN", ""),
    "SERVER_URL": os.getenv("ELASTIC_APM_SERVER_URL", ""),
    "ENABLED": os.getenv("ELASTIC_APM_ENABLED", "false").lower() == "true",
}

if app.config["ELASTIC_APM"]["ENABLED"] and app.config["ELASTIC_APM"]["SERVER_URL"]:
    ElasticAPM(app)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

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

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8008)
