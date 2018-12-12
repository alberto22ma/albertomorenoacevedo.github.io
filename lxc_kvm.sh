#!/usr/bin/env bash

IPLXC='10.0.0.2'
IPKVM='10.0.0.3'

VOLUMEN='/dev/sda1'

KVM='kvmpracticalxc'

EXTIFACE='br0'

SSHCMD='ssh -q -o BatchMode=yes'

user='postgres'

contenedorpostgreslxc_status=$(lxc-info -n contenedorpostgreslxc -sH)

function Salida {
    printf 'Saliendo del script..\n'
    exit
}
trap Salida EXIT INT TERM

#comprobar lxc
if [[ $contenedorpostgreslxc_status != "RUNNING" ]];
then
     # start contenedorpostgreslxc
    lxc-start -n contenedorpostgreslxc

    # check contenedorpostgreslxc status
    cont1_status=$(lxc-info -n contenedorpostgreslxc -sH)

    until  [[ $contenedorpostgreslxc_status == "RUNNING" ]]
        do
            echo "Initializing contenedorpostgreslxc"
        done

    #añadir volumen
    echo "Adding volume to contenedorpostgreslxc"
    lxc-device -n contenedorpostgreslxc add /dev/lxc/additional

    echo "Mounting"
    lxc-attach -n contenedorpostgreslxc -- mount /dev/lxc/additional /home/lxc
    echo "Mounted"
fi

#parar postgres
echo "Parando postgres..."
lxc-attach -n contenedorpostgreslxc -- systemctl stop postgresql

# limite ram 
echo "Limite ram"
lxc-cgroup -n contenedorpostgreslxc memory.limit_in_bytes 500M


until [[ -n "${IPLXC}" ]] 
        do
            echo "Getting contenedorpostgreslxc IP"
            sleep 1
            IPLXC=$(lxc-info -n contenedorpostgreslxc -iH)
        done

#comprobar kvm
function ComprobarKVM(){
    printf 'Comprobando estado de la máquina KVM...\n'
    if [[ $(virsh dominfo $KVM | grep -Ei '.*state:[[:space:]]*running.*') ]]; then
        printf 'Máquina encendida..\n'
    else
        printf 'Máquina apagada.. Encendiendo..\n'
        maxintentos=3
        intento=0
        while (( intento < maxintentos )) && [[ ! $(virsh dominfo $KVM | grep -Ei '.*state:[[:space:]]*running.*') ]]; do
            ((intento++))
            printf "Intentando arrancar la máquina KVM (${intento}/${maxintentos})...\n"
            virsh start $KVM
            [[ ! $(virsh dominfo $KVM | grep -Ei '.*state:[[:space:]]*running.*') ]] && sleep 5
        done
            [[ ! $(virsh dominfo $KVM | grep -Ei '.*state:[[:space:]]*running.*') ]] && \
                printf 'Error iniciando la máquina KVM...\n' && \
                exit 1
    fi
}

#ram 90%
    if  [[ $contenedorpostgreslxc_mem -ge '450' ]];
    then
        contenedorpostgreslxc_status='sobrepasa limite ram'
        
        # parar lxc
        echo "Parar contenedorpostgreslxc"
        lxc-stop -n contenedorpostgreslxc
        
        # demontar disco lxc
        lxc-attach -n contenedorpostgreslxc -- umount /dev/lxc/additional /home/lxc
        
            
function ConectarVolumen(){
    printf 'Conectar disco a KVM'
    virsh attach-disk $KVM \
        --source $VOLUMEN \
        --targetbus virtio \
        --driver qemu \
        --subdriver raw \
        --cache none \
        --sourcetype block \
        --live
    (( $? != 0 )) && \
        printf 'No se puede conectar el volumen' && \
        exit 1
    printf 'Disco conectado'
}
fi

function MontarDispositivo(){
    printf 'Montando unidad'
    $SSHCMD root@${IPKVM} mount /dev/vdb /home/postgres/postgresql &>/dev/null
    (( $? != 0 )) && \
        printf 'No se pudo montar el disco' && \
        exit 1
    printf 'Disco conectado'
}
fi

function kvmIpTables(){
    printf 'Creando reglas DNAT de IPTABLES...\n'
    iptables -t nat -D PREROUTING -p tcp --dport 5432 -i br0 -j DNAT --to ${IPLXC}:5432
    iptables -t nat -A PREROUTING -p tcp --dport 5432 -i br0 -j DNAT --to ${IPKVM}:5432
}

    
fi