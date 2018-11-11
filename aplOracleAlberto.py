from bottle import route, run, template, static_file, request, redirect, response, get, post, default_app

@route('/')
def login():
    return '''
        <!DOCTYPE html>
        <html lang="es">
        <title>Apl acceso Oracle</title>
        <center>
        <h3>Acceso a oracle</h3>
        <form action="/" method="post">
            <input name="username" type="text" placeholder="Usuario" /><br>
            <input name="password" type="password" placeholder="Contraseña" /><br>
            <input name="host" type="text" placeholder="host" /><br>
            <input name="database" type="text" placeholder="Base datos" /><br>
            <input value="Login" type="submit" />
        </form>
        <p></p>
        </center>'''

@route('/',method='POST')

def do_login():

	username = request.forms.get('username')
	password = request.forms.get('password')
	host = request.forms.get('host')
	database = request.forms.get('database')

	orcl = []

	connection = cx_Oracle.connect(str(username)+"/"+str(password)+"@"+str(host)+"/"+str(basedatos))
	cursor = connection.cursor()
	cursor.execute("select * from juanpe")
	info = cursor.fetchall()
	for datos in info:
		orcl.append(datos[1])
	return template('login.tpl', orcl=orcl)
	cursor.close()

@route('/views/<filepath:path>')
def server_static(filepath):
	return static_file(filepath, root='views')

run (host='0.0.0.0', port='8080', debug='True')
