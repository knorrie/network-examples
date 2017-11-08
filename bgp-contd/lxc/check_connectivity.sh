#!/bin/sh

routers='0 1 2 10 11 12 20'
for src in $routers
do
    for dst in $routers
    do
	lxc-attach -n R$src -- ping6 -c 1 r$dst
	if [ $? -ne 0 ]
	then
	   echo
	   echo "Connectivity test failed: R$src -> R$dst"
	   exit 1
	fi
    done
done

echo
echo "====  Success ===="
