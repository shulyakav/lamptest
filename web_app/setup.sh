#!/bin/bash

# Update and install Apache, WSGI, and MySQL client
sudo yum update -y
sudo yum install -y httpd mysql
sudo amazon-linux-extras install -y epel
sudo yum install -y python3 python3-pip
sudo yum install httpd httpd-devel python3-devel gcc -y
cd /tmp
wget https://github.com/GrahamDumpleton/mod_wsgi/archive/refs/tags/4.9.0.tar.gz
tar -xzf 4.9.0.tar.gz
cd mod_wsgi-4.9.0/
./configure --with-python=/usr/bin/python3
make
sudo make install
sudo bash -c  'cat > /etc/httpd/conf.modules.d/mod_wsgi.cong << 'EOF'
LoadModule wsgi_module /usr/lib64/httpd/modules/mod_wsgi.so
EOF
'



# Enable and start Apache
sudo systemctl enable httpd
sudo systemctl start httpd

# Create a virtual environment and Flask application
sudo mkdir /var/www/flaskapp
sudo chown -R ec2-user:ec2-user /var/www/flaskapp
cd /var/www/flaskapp
sudo python3 -m venv venv
source venv/bin/activate
sudo chown -R ec2-user:ec2-user /var/www/flaskapp
pip install Flask mysql-connector-python pymysql

# Install Flask and MySQL connector
sudo pip3 install Flask mysql-connector-python pymysql

cat > /var/www/flaskapp/app.py << 'EOF'
from flask import Flask, render_template
import pymysql.cursors

app = Flask(__name__)

# Database connection info
DB_HOST = '${database_host}'
DB_USER = '${database_user}'
DB_PASSWORD = '${database_password}'
DB_NAME = '${database_name}'

# Connect to the database
connection = pymysql.connect(host=DB_HOST,
                             user=DB_USER,
                             password=DB_PASSWORD,
                             database=DB_NAME,
                             cursorclass=pymysql.cursors.DictCursor)

@app.route('/')
def index():
    with connection.cursor() as cursor:
        sql = "SELECT * FROM simpletable"
        cursor.execute(sql)
        result = cursor.fetchall()
    return render_template('index.html', rows=result)

if __name__ == '__main__':
    app.run(debug=True)
EOF




mkdir /var/www/flaskapp/templates
cat > /var/www/flaskapp/templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>MySQL Data</title>
</head>
<body>
    <h1>Table Data</h1>
    <table border="1">
        <tr>
            <!-- Adjust these headers based on your table columns -->
            <th>id</th>
            <th>data</th>
        </tr>
        {% for row in rows %}
        <tr>
            <td>{{ row['id'] }}</td>
            <td>{{ row['data'] }}</td>
        </tr>
        {% endfor %}
    </table>
</body>
</html>

EOF




# Create WSGI file
cat > /var/www/flaskapp/flaskapp.wsgi << 'EOF'
import sys
sys.path.insert(0, '/var/www/flaskapp')

from app import app as application
EOF

# Configure Apache to serve the Flask app
sudo bash -c 'cat > /etc/httpd/conf.d/flaskapp.conf << 'EOF'
LoadModule wsgi_module modules/mod_wsgi.so
<VirtualHost *:80>
    ServerName :80

    WSGIDaemonProcess app threads=5 python-home=/var/www/flaskapp/venv python-path=/var/www/flaskapp/bin
    WSGIScriptAlias / /var/www/flaskapp/flaskapp.wsgi

    <Directory /var/www/flaskapp>
        Order allow,deny
        Allow from all
    </Directory>
</VirtualHost>
EOF
'

 
# Restart Apache to apply changes
sudo systemctl restart httpd
