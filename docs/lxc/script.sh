#!/bin/bash
# known issue chown also removed setuid and setgid bit
# chmod 4755 filename setuid
# chmod 2755 filename setgid
echo container name?
read containerName
echo new subuid/subgid?
read subuid
echo previous subuid?
read preSubuid
echo new uid?
read uid
echo new gid?
read gid
IFS=$'\n'
sp="/-\|"
sc=0
spin() {
    printf "\b${sp:sc++:1}"
    ((sc == ${#sp})) && sc=0
}
endspin() {
    printf "\r%s\n" "$@"
}

sudo chown $subuid:$gid $containerName
sudo chown $uid:$gid $containerName/config

for d in $(sudo find $containerName/rootfs -type d,f); do

    spin
    userPermission=$(stat -c '%u' $d)
    groupPermission=$(stat -c '%g' $d)

    newUp=$(expr $userPermission - $preSubuid + $subuid)
    newGp=$(expr $groupPermission - $preSubuid + $subuid)

    if [[ -d $d ]]; then
        echo sudo chown $newUp:$newGp $d >>dir.log
        sudo chown $newUp:$newGp $d
    elif [[ -f $d ]]; then
        echo sudo chown $newUp:$newGp $d >>file.log
        sudo chown $newUp:$newGp $d

    else
        echo sudo chown $newUp:$newGp $d >>others.log
        sudo chown $newUp:$newGp $d
        exit 1
    fi

done

for d in $(sudo find $containerName/rootfs -type l); do

    spin
    userPermission=$(stat -c '%u' $d)
    groupPermission=$(stat -c '%g' $d)

    newUp=$(expr $userPermission - $preSubuid + $subuid)
    newGp=$(expr $groupPermission - $preSubuid + $subuid)

    echo sudo chown -h $newUp:$newGp $d >>symlink.log
    sudo chown -h $newUp:$newGp $d
done
