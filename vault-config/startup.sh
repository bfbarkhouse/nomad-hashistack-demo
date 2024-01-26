#!/bin/sh

nohup ./vault/config/entrypoint.sh server > vault.log & 
echo $VAULT_ADDR
#echo $UNSEAL_KEY

while true
    do
        vault status | grep Sealed
        running=$?
        echo $running
        if [ $running = "0" ]
            then
                echo "Unsealing Vault"
                vault operator unseal $UNSEAL_KEY
                break
            else
               echo "Vault not running yet"
                sleep 5 
        fi
    done
vault status
apk update && apk add ca-certificates
cp /vault/config/tfe-ca.crt /usr/local/share/ca-certificates/tfe-ca.crt
chmod 644 /usr/local/share/ca-certificates/tfe-ca.crt
update-ca-certificates
tail -f vault.log