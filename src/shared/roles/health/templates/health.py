import subprocess
from flask import Flask

app = Flask(__name__)
service_name = "${SERVICE_NAME}"

@app.route('/')
def rootPath():
	return 'OK'

@app.route('/status')
def status():
	result = subprocess.check_output(["service", service_name, "status"])
	if "running" in result:
		return 'OK'
	else:
		return 'Not running', 404

if __name__ == '__main__':
	app.run()