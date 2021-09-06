mysql -u root -ppassword -e "ALTER USER 'root' IDENTIFIED WITH mysql_native_password BY 'password';"
mysql -u root -ppassword -e "flush privileges;"
mysql -u root -ppassword world < "/docker-entrypoint-initdb.d/world.sql"
