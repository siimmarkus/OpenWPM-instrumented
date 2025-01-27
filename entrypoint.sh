#!/bin/bash

# Create display
Xvfb $DISPLAY -ac &
# Start VNC
x11vnc -forever -passwdfile $VNC_PASSWORD_FILE &
# Initialize state file
echo '{ "next_idx": 0, "finished": false }' > state.json

# Until the python script has updated the "finished" value to true
until jq -e '.finished' state.json | grep -q true
do
  # Run OpenWPM
  python demo.py --domainfile tranco.txt --maxdomains 10000

done
