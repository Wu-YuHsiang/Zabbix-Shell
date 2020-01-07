#! /bin/bash

rm -rf /root/2019Q4/2019_APP.txt

for DOMAIN in `cat domain.txt`;
  do
    echo $DOMAIN
    httping $DOMAIN:10000 -c 10 --timestamp -z -s >> /root/2019Q4/2019_APP.txt
done
