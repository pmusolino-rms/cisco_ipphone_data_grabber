#!/bin/sh
#  The following script queries call manager via SNMP to get basic phone data then visits the phones web page to grab serial number.
# html-xml-utils is required for hxselect 
#GET INDEXES
phone_index_array=()
CUCM="1.2.3.4"
COMMUMNITY="somecommunity"
CSV_FILE="phone_data.csv"

/bin/touch $CSV_FILE
# Creating but not really using associative array as it is for debugging.
#declare -A phone
# Get Index of all phones
# OIDs of phones availble at the following URL
# http://www.oidview.com/mibs/9/CISCO-CCM-MIB.html
phone_index_string=$(/usr/bin/snmpwalk -Oq -v2c -c $COMMUNITY $CUCM 1.3.6.1.4.1.9.9.156.1.2.1.1.6 | awk {'print $1'} | cut -d. -f10)
while read -r line; do
    phone_index_array+=("$line")
done <<< "$phone_index_string"

for i in ${phone_index_array[@]}; do
    IP=$(/usr/bin/snmpget -Oqv -v2c -c $COMMUNITY $CUCM 1.3.6.1.4.1.9.9.156.1.2.1.1.6.$i)
    USER=$(/usr/bin/snmpget -Oqv -v2c -c $COMMUNITY $CUCM 1.3.6.1.4.1.9.9.156.1.2.1.1.5.$i)
    DESC=$(/usr/bin/snmpget -Oqv -v2c -c $COMMUNITY $CUCM 1.3.6.1.4.1.9.9.156.1.2.1.1.4.$i)
    REGISTERED=$(/usr/bin/snmpget -Oqv -v2c -c $COMMUNITY $CUCM 1.3.6.1.4.1.9.9.156.1.2.1.1.7.$i)
    DEVICE_TYPE=$(/usr/bin/snmpget -Oqv -v2c -c $COMMUNITY $CUCM 
    EXTENSION=$(/usr/bin/snmpwalk -Oqv -v2c -c $COMMUNITY $CUCM 1.3.6.1.4.1.9.9.156.1.2.5.1.2.$i | tr -d '\n')
    SERIAL=$(curl -s 0 $IP/Device_Information.html | awk '/Serial\ Number/,/Model\ Number/' | grep -ie '</tr>' | sed 's/\<\/tr\>//' | hxselect -c b 2>/dev/null)
    if [ -z "$SERIAL" ]; then
        SERIAL=$(curl -s 0 $IP/DeviceInformation | awk '/Serial\ Number/,/Model\ Number/'  | grep -e '^<TD>' | hxselect -c B 2>/dev/null)
    fi
    csv="$SERIAL,$USER,$DESC,$REGISTERED,$EXTENSION"
#    phone[$IP]=$csv
    echo "$IP,$csv" >> $CSV_FILE
    done

#Debug
#for i in "${!phone[@]}"; do
#    echo "IP : $i"
#    IFS=',' read -r -a phone_value_array <<< "${phone[$i]}"
#    echo "Serial: ${phone_value_array[0]}"
#    echo "User: ${phone_value_array[1]}"
#    echo "Desc: ${phone_value_array[2]}"
#    echo "Status: ${phone_value_array[3]}"
#    echo "Extension: ${phone_value_array[4]}"
#    done
