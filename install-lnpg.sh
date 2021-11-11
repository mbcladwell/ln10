#!/bin/sh

  mkdir lndata
    echo "export PGDATA=\"/home/admin/lndata\"" >> /home/admin/.bashrc
    export PGDATA="/home/admin/lndata"
    export LC_ALL="C"
    initdb -D /home/admin/lndata

    sudo chmod -R a=rwx /home/admin/ln10

    sudo sed -i 's/host[ ]*all[ ]*all[ ]*127.0.0.1\/32[ ]*md5/host    all        all             127.0.0.1\/32        trust/' /home/admin/lndata/pg_hba.conf
    sudo sed -i 's/\#listen_addresses =/listen_addresses =/'  /home/admin/lndata/postgresql.conf

    pg_ctl -D /home/admin/lndata -l logfile start
    
    psql -U admin -h 127.0.0.1 postgres -a -f /home/admin/ln10/initdba.sql
    psql -U admin -h 127.0.0.1 lndb -a -f /home/admin/ln10/initdbb.sql
    psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/create-db.sql
    psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/example-data.sql   

echo "LIMS*Nucleus database successfully installed."
echo "Run 'nohup ~/run-limsn.sh' to start the application server in detached mode."
