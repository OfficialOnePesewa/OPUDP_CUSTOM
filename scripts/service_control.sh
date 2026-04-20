#!/bin/bash
echo "1) Start  2) Stop  3) Restart  4) Status"
read -p "Choice: " opt
case $opt in
    1) systemctl start opudp-custom opudpgw;;
    2) systemctl stop opudp-custom opudpgw;;
    3) systemctl restart opudp-custom opudpgw;;
    4) systemctl status opudp-custom opudpgw --no-pager;;
esac
