#!/bin/sh
UID=`uci get network.wan.macaddr | sed s/:/%3A/g`
rm -f pipe
mkfifo pipe
trap "rm -f pipe" EXIT
while true ; 
do 
   #use read line from pipe to make it blocks before request comes in,
   #this is the key.
   # wget http://x.x.x.x:8888/token=xxxx&UID=xxxxx
   #http://1.1.1.1:8888/?Verification=T&Vermsg=OK%2C%E4%B8%AD%E6%96%87%E4%B9%9F%E8%A1%8C&Key=&UserIdentification=ecd2dc85&DeviceID=00%3A0a%3Aeb%3A82%3Abb%3Ae6
  { read line<pipe; Body=$(echo -en '<html>Sample html</html>') ; \
      echo -en "HTTP/1.0 200 OK\nContent-Type: text/html\nContent-Length: ${#Body}\n\n$Body" ; \
	  if  echo "$line" | grep -q "DeviceID=$UID" ; then \
		if echo "$line" | grep -q "Verification=T" ; then \
			  token=`echo "$line" | cut -d '/'  -f2 | cut -d '&' -f4 | cut -d '=' -f2` ; \
			  TRUSTED_MAC=`logread | grep nodogsplash | grep $token | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | head -n 1` ; \
			  [ -n "$TRUSTED_MAC" ] && ndsctl trust "$TRUSTED_MAC" ; \
		 fi ; \
	  fi 
   }  | nc -l  -p 8888 > pipe;  

done
