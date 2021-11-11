#!/bin/sh

source /home/admin/.guix-profile/etc/profile 
    export LC_ALL="C"
  
    sudo chmod -R a=rwx /home/admin/ln10
    sudo pg_ctl -D /var/lib/postgresql/11/main -l /var/log/postgresql/postgresql-11-main.log stop
    sudo sed -i 's/host[ ]*all[ ]*all[ ]*127.0.0.1\/32[ ]*md5/host    all        all             127.0.0.1\/32        trust/' /etc/postgresql/11/main/pg_hba.conf
    sudo sed -i 's/\#listen_addresses =/listen_addresses =/'  /etc/postgresql/11/main/postgresql.conf
    sudo pg_ctl -D /var/lib/postgresql/11/main -l /var/log/postgresql/postgresql-11-main.log start
    
    psql -U admin -h 127.0.0.1 postgres -a -f /home/admin/ln10/initdba.sql
    psql -U admin -h 127.0.0.1 lndb -a -f /home/admin/ln10/initdbb.sql
    psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/create-db.sql
    psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/example-data.sql   

echo "LIMS*Nucleus database successfully installed."
echo "Run 'nohup ~/run-limsn.sh' to start the application server in detached mode."


