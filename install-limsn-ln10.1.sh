#!/bin/sh

# We require Bash but for portability we'd rather not use /bin/bash or
# /usr/bin/env in the shebang, hence this hack.
if [ "x$BASH_VERSION" = "x" ]
then
    exec bash "$0" "$@"
fi

# set -e
# [ "$UID" -eq 0 ] || { echo "This script must be run as root."; exit 1; }


PAS=$'[ \033[32;1mPASS\033[0m ] '
ERR=$'[ \033[31;1mFAIL\033[0m ] '
WAR=$'[ \033[33;1mWARN\033[0m ] '
INF="[ INFO ] "
# ------------------------------------------------------------------------------
#+UTILITIES

_err()
{ # All errors go to stderr.
    printf "[%s]: %s\n" "$(date +%s.%3N)" "$1"
}

_msg()
{ # Default message to stdout.
    printf "[%s]: %s\n" "$(date +%s.%3N)" "$1"
}

_debug()
{
    if [ "${DEBUG}" = '1' ]; then
        printf "[%s]: %s\n" "$(date +%s.%3N)" "$1"
    fi
}

# Return true if user answered yes, false otherwise.
# $1: The prompt question.
prompt_yes_no() {
    while true; do
        read -rp "$1" yn
        case $yn in
            [Yy]*) return 0;;
            [Nn]*) return 1;;
            *) _msg "Please answer yes or no."
        esac
    done
}

welcome()
{
    cat<<"EOF"

 _______________________  |  _ |_  _  _ _ _|_ _  _         
|O O O O O O O O O O O O| |_(_||_)(_)| (_| | (_)| \/       
|O O O O O O 1 O O O O O|                         /        
|O O O O O O O O O O O O|  /\    _|_ _  _ _  _ _|_. _  _   
|O O O O O O O O O O O O| /~~\|_| | (_)| | |(_| | |(_)| |  
|O O 1 O O O O O 1 O 1 O|  _                               
|O O O O O O O O O O O O| (  _ |   _|_. _  _  _            
|O O O 1 O O O O O O O O| _)(_)||_| | |(_)| |_)    
|O O O O O O O O O O O O|
 -----------------------  info@labsolns.com

This script installs LIMS*Nucleus on your system

http://www.labsolns.com

EOF
    echo -n "Press return to continue..."
    read -r
}

query()
{
    echo Enter IP address:
    read IPADDRESS
    
    echo Maximum number of plates per plate set:
    read MAXNUMPLATES
}

updatesys()
{
    sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes update
    sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt-get  --assume-yes install gnupg git nscd postgresql-client nano
}


guixinstall()
{
    wget 'https://sv.gnu.org/people/viewgpg.php?user_id=15145' -qO - | sudo -i gpg --import -
    wget 'https://sv.gnu.org/people/viewgpg.php?user_id=127547' -qO - | sudo -i gpg --import -

    git clone --depth 1 https://github.com/mbcladwell/ln10.git 

    sudo ./ln10/guix-install-mod.sh

  ## using guile-3.0.2
    guix install glibc-utf8-locales guile-dbi
    sudo guix install glibc-utf8-locales
    export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
             
    guix package --install-from-file=/home/admin/ln10/limsn.scm

    mkdir /home/admin/.configure
    mkdir /home/admin/.configure/limsn
    cp /home/admin/ln10/artanis.conf /home/admin/.configure/limsn

    sudo sed -i "s/host.name = 127.0.0.1/host.name = $IPADDRESS/" /home/admin/.configure/limsn/artanis.conf
    sudo sed -i "s/cookie.maxplates = 100/cookie.maxplates = $MAXNUMPLATES/"  /home/admin/.configure/limsn/artanis.conf

    
    source /home/admin/.guix-profile/etc/profile     
     export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"    
}

initdb()
{
    _msg "configuring db"

    ## note this must be in separate script:
##    /home/admin/ln10/install-lnpg.sh

source /home/admin/.guix-profile/etc/profile 
    export LC_ALL="C"
    
    sudo chmod -R a=rwx /home/admin/ln10

mkdir lndata

echo "export PGDATA=\"/home/admin/lndata\"" >> /home/admin/.bashrc
export PGDATA="/home/admin/lndata"


initdb -D /home/admin/lndata
    
    sudo sed -i 's/host[ ]*all[ ]*all[ ]*127.0.0.1\/32[ ]*md5/host    all        all             127.0.0.1\/32        trust/' /home/admin/lndata/pg_hba.conf
    sudo sed -i 's/\#listen_addresses =/listen_addresses =/'  /home/admin/lndata/postgresql.conf
    pg_ctl -D /home/admin/lndata -l logfile start
    
    psql -U admin -h 127.0.0.1 postgres -a -f /home/admin/ln10/initdba.sql
    psql -U admin -h 127.0.0.1 lndb -a -f /home/admin/ln10/initdbb.sql
    psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/create-db.sql
    psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/example-data.sql   


    
}

main()
{
    local tmp_path
    welcome
    export DEBIAN_FRONTEND=noninteractive 
    _msg "Starting installation ($(date))"

    query
    updatesys
    guixinstall
    initdb  
    
    _msg "${INF}cleaning up ${tmp_path}"
    rm -r "${tmp_path}"

    _msg "${PAS}LIMS*Nucleus has successfully been installed!"

    # Required to source /etc/profile in desktop environments.
    _msg "${INF}Run 'nohup ~/run-limsn.sh &' to start the server in detached mode."
 }

main "$@"

