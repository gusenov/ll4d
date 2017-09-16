#!/bin/bash

# Usage:
#  $ "./mysql/secure.sh" -c="devel-web-server" -u="root" -p="Enter-Your-Password-Here"
#  $ "./mysql/secure.sh" --container="devel-web-server" --user="root" --password="Enter-Your-Password-Here"

source "./argument/container.sh"
source "./argument/user.sh"
source "./argument/password.sh"

set -x # echo on

# Проверяем настроен для VALIDATE PASSWORD PLUGIN для MySQL:
if lxc exec "$container" -- echo "SHOW VARIABLES LIKE 'validate_password_policy';" \
    | lxc exec "$container" -- mysql -u $user -p$password -N \
        | grep --silent validate_password_policy; then

    validate_password_plugin=1
else
    validate_password_plugin=0
fi

# install expect if needed:
if [ `lxc exec "$container" -- which expect` ]; then
    expect_already_installed=1
else
    expect_already_installed=0
    lxc exec "$container" -- sudo apt-get -qq update
    lxc exec "$container" -- sudo apt-get -qq install expect
fi

lxc exec "$container" -- expect -f - <<-EOF
    set timeout 10
    spawn mysql_secure_installation --user=$user --password=$password
    
    # expect "Enter password for user root:"
    # send -- "$password\r"
    
    if { $validate_password_plugin == 0} {
        # Would you like to setup VALIDATE PASSWORD plugin?
        expect "Press y|Y for Yes, any other key for No:"
        send -- "y\r"
        
        expect "Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:"
        send -- "2\r"
    }
    
    expect "Change the password for root ? ((Press y|Y for Yes, any other key for No) :"
    send -- "\r"
    
    expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
    send -- "y\r"
    
    expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
    send -- "y\r"
    
    expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
    send -- "y\r"
    
    expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
    send -- "y\r"
    
    expect eof
EOF

if [ $expect_already_installed -eq 0 ]; then
    # This will remove just the expect package itself.
    # sudo apt-get -qq remove expect
    
    # This will remove the expect package and any other dependant packages which are no longer needed.
    # sudo apt-get -qq remove --auto-remove expect
    
    # If you also want to delete your local/config files for expect then this will work.
    # sudo apt-get -qq purge expect
    
    # Or similarly, like this expect
    lxc exec "$container" -- sudo apt-get -qq purge --auto-remove expect
else
    :
fi
