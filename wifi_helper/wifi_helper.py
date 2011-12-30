#!/usr/bin/python3

#################################################
#author: Jorge Haddad (sumeniac)                #
#contact: jorgejch@gmail.com        	        	#
#							        	#
#last review date: march 2011      			#
#                                               #
#notes: This script is inteded as slight        #
#break on looking up wireless access points     #
#and writing the corresponding wpa_supplicant   #
#entries, from the command line.                #
#                                               #
#dependencies:                                  #
#       *Python 3                               #
#       *wireless-tools                         #
#       *wpa_supplicant     				#
#usage: wifi_helper.py [interface]              #
#################################################

import re
import subprocess
import time
import tempfile
import sys
import os

#Variables containing paths of the necessary executables.
iwlist_path="/sbin/iwlist"                      #wireless-tools package
iwconfig_path="/sbin/iwconfig"                  #wireless-tools package
wpa_passphrase_path="/usr/bin/wpa_passphrase"   #wpa_supplicant package

#Tests for interface argument, defaults to 'wlan0'.
if (len(sys.argv) > 1):
    interface = sys.argv[1]
else:
    interface = "wlan0"

def check_for_files():
#Checks if the necessary executables are present.

    if not os.path.isfile(iwlist_path):
        print("iwlist not found on /sbin/, please specify correct path on script.")
        sys.exit()

    if not os.path.isfile(iwconfig_path):
        print("iwconfig not found on /sbin/, please specify path on script.")
        sys.exit()

    if not os.path.isfile(wpa_passphrase_path):
        print("wpa_passphrase not found on /usr/bin/, please specify path on script.")
        sys.exit()

    return True

def acquire_spots(interface) :
#Parses iwlist output and extracts visible access points. Returns list of
#dictionaries containing data for each points found.

    buff_file = tempfile.TemporaryFile(mode='w+')

    command=iwlist_path + " " + interface + "  scanning"
    p = subprocess.Popen(command, stdout=buff_file, shell=True)
    p.wait()
    
    while True :

        buff_file.seek(0)
        first_line = buff_file.readline()

        ok = "Scan completed"
        busy = "Interface doesn't support scanning : Device or resource busy"
        network_down = "Failed to read scan data : Network is down"
   
        if (busy in first_line) :
            time.sleep(1)
            buff_file.close()
            buff_file = tempfile.TemporaryFile()
            p = subprocess.Popen("/sbin/iwlist wlan0 scanning",stdout=buff_file, shell=True)
            p.wait()
        elif (network_down in first_line):
            print("Wireless network down.")
            buff_file.close()
            sys.exit()
        elif (ok in first_line):
            break
        else : 
            print("Something unexpected happened. Please send output to Sumeniac.")
            print(first_line)
            for line in buff_file:
                print(line)
            sys.exit()
    
    spots = list()
    x=-1 
    matches = { \
            'ESSID' : re.compile('ESSID:(".+")'), \
            'Quality' : re.compile('Quality=(\d+/\d+)'), \
            'Encryption Key' :  re.compile('Encryption key:(.+)'), \
            'Encryption Type' : re.compile('(WPA)') \
            }
    
    for line in buff_file :
        if ("Cell" in line):
            x = x+1
            spots.append(dict())
            continue
    
        if x>=0 :
            temp = spots[x]
            for field, regex in matches.items():
                match = regex.search(line)
                if match:
                    temp[field] = match.group(1)

    buff_file.close()                
    
    return spots
    
def print_spots(spots) :
#Prints the access points found.

    if len(spots)>0:
        print ("\nAvaible access points listed bellow.\n")
        
        for i, spot in enumerate(spots):
            print ("\nAcess point number {0}:\n".format(i))      
            
            for key in iter(spot.keys()):
                print("\t" + key + " = " + spot[key])
    else:
        print("No avaible access points.")
        sys.exit()

def compile_conf_entry(spots, interface): 
#Compiles (outputs) an wpa_supplicant.conf entry for the choosen access point.

    buff_file = tempfile.TemporaryFile(mode='w+')

    command=iwlist_path + " " + interface
    p = subprocess.Popen("/sbin/iwconfig wlan0",stdout=buff_file, shell=True)
    p.wait()
    buff_file.seek(0)

    essid_regex = re.compile('ESSID:".*"')

    for line in buff_file:
        essid_match = essid_regex.search(line)
        if essid_match:
            if ( essid_match.group() != 'ESSID:""' ):
                print ("\nConnected to {0}.\n".format(essid_match.group()))
            else: 
                print ("\nNot connected to any acess point.\n")
            break

    buff_file.close()

    option = input("\nWhich acess point would you like to connect to (or 'e' to exit)? (0-{0}) ".format(len(spots)-1))
    if (option == 'e'):
        sys.exit()
    spot = spots[int(option)]

    essid=spot['ESSID']

    if ('Encryption Type' in spot):
        buff_file = tempfile.TemporaryFile(mode='w+')
        command=wpa_passphrase_path + " " + essid + " " + \
                input("What's the passphrase? (de 8 à 63 char) ")

        p = subprocess.Popen(command,stdout=buff_file, shell=True)
        p.wait()
        buff_file.seek(0)

        for line in buff_file:
            p = re.match("^\s+(psk=.+)", line)
            if p:
                pskKey = p.group(1)
                break

        buff_file.close()
        string = "network={ \
                    \n\tssid=" + essid + \
                    "\n\tproto=WPA \
                    \n\tkey_mgmt=WPA-PSK \
                    \n\tpairwise=CCMP TKIP \
                    \n\tgroup=CCMP TKIP WEP104 WEP40 \
                    \n\t"+ pskKey + \
                    "\n\tpriority=3 \
                 \n}"

    elif ('Encryption Type' not in spot and "on" in spot['Encryption key']):
        wepKey=input("What's the WEP key? ")
        string = "network={ \
                        \n\tssid=" + essid + \
                        "\n\tkey_mgmt=NONE \
                        \n\twep_key0=" + wepKey + \
                        "\n\tpriority=3 \
                    \n}"
    elif ("off" in spot['Encryption key']):
        string = "network={ \
                        \n\tssid="+ essid + \
                        "\n\tkey_mgmt=NONE \
                        \n\tpriority=3 \
                    \n}"
    else:
        string = "Error. Debug."

    print ('\n'+ string + "\n\nPaste 'network' entry on wpa_supplicant.conf.\n")

#Main:
if check_for_files():
    spots = acquire_spots(interface)
    print_spots(spots)
    compile_conf_entry(spots, interface)
    sys.exit()
