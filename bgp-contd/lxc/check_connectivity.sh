#!/bin/sh

routers='0 1 2 10 11 12 20'
for src in $routers
do
	for dst in $routers
	do
		lxc-attach -n R$src -- ping6 -c 1 r$dst >/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			echo "[FAIL] R$src -> R$dst"
		else
			echo "[OK] R$src -> R$dst"
		fi
	done
done
