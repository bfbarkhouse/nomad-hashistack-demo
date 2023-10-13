#!/bin/sh

nohup ./vault/config/entrypoint.sh server > vault.log & 
export VAULT_ADDR="http://10.0.0.194:8200"

while true
    do
        vault status | grep Sealed
        running=$?
        echo $running
        if [ $running = "0" ]
            then
                echo "Unsealing Vault"
                vault operator unseal xs3I3cy54RdajJhrUCpvWpnaexok6/lZLBAD4pYNo/w=
                break
            else
               echo "Vault not running yet"
                sleep 5 
        fi
    done
vault status
tail -f vault.log