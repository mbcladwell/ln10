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


updatesys()
{
    sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes update
    sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt-get  --assume-yes install gnupg git nscd postgresql postgresql-client  postgresql-contrib nano


  ##  texinfo ca-certificates postgresql postgresql-client postgresql-contrib libpq-dev git nano zlib1g-dev libnss3 libnss3-dev libgmp-dev libgc-dev libffi-dev libltdl-dev libintl-perl libiconv-hook-dev nettle-dev 
  
}


guixinstall()
{
    wget 'https://sv.gnu.org/people/viewgpg.php?user_id=15145' -qO - | sudo -i gpg --import -
    wget 'https://sv.gnu.org/people/viewgpg.php?user_id=127547' -qO - | sudo -i gpg --import -
    sudo ./ln10/guix-install-mod.sh

  ## using guile-3.0.2
    guix install glibc-utf8-locales guile-dbi
    sudo guix install glibc-utf8-locales
    export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"
             
    guix package --install-from-file=/home/admin/ln10/artanis51.scm

    source /home/admin/.guix-profile/etc/profile 


      guix install glibc-utf8-locales
     export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale"


    
}



initdb()
{
    _msg "configuring db"
    git clone --depth 1 https://github.com/mbcladwell/ln10.git 

    sudo chmod -R a=rwx /home/admin/ln10

    PGMAJOR=$(eval "ls /etc/postgresql")
    PGHBACONF="/etc/postgresql/$PGMAJOR/main/pg_hba.conf"
    sudo sed -i 's/host[ ]*all[ ]*all[ ]*127.0.0.1\/32[ ]*md5/host    all        all             127.0.0.1\/32        trust/' $PGHBACONF

    PGCONF="/etc/postgresql/$PGMAJOR/main/postgresql.conf"
    sudo sed -i 's/\#listen_addresses =/listen_addresses =/' $PGCONF

    eval "sudo pg_ctlcluster $PGMAJOR main restart"

psql -U postgres -h 127.0.0.1 -a -f /home/admin/ln10/initdba.sql
psql -U postgres -h 127.0.0.1 lndb -a -f /home/admin/ln10/initdbb.sql
psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/create-db.sql
psql -U ln_admin -h 127.0.0.1 -d lndb -a -f /home/admin/ln10/example-data.sql
   
}



main()
{
    local tmp_path
    welcome
    export DEBIAN_FRONTEND=noninteractive 
    _msg "Starting installation ($(date))"
    
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

