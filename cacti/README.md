cacti
=====

A bunch of cacti stuff I want to keep.

http://www.cacti.net/

sshwrapper.sh
-------------
Wrapper for Cacti SSH connections.  Prevents the remote cacti user from performing any actions we don't want them to.  This one is specialized to work with the Percona Monitoring Plugins (Formerly "mysql-cacti-templates").

.ssh/authorized_keys:

    command="/usr/local/bin/sshwrapper.sh" <key> user@host

http://www.percona.com/software/percona-monitoring-plugins

micasaverde/get_mcv.py
----------------
Cacti script to get your Vera(lite) hooked up to the graphing machines!

* For use with the cacti_host_template_micasaverde_* files in the templates/ directory
* Script is written for use with **one-minute cacti polling**.  Edit the script and change 60 to 300 for a 5-minute poller.  If you do not do this you will most likely miss door/window contact events.

How to use:
* Using Host Templates: Create a new cacti host for each sensor.  Use the IP address of your vera controller for all of them.  Be sure you are selecting the appropriate host template to match the device you're adding.
* Using Graph Templates: Create one host with the IP of your vera controller and add graphs invididually for each device.
* Creating graphs:  You will need to know the ID number of the device in order to create graphs for it.  This information is available a variety of ways, but the easiest is probably by pointing your web broswer here:  http://<your.vera.box.ip>:3480/data_request?id=sdata&output_format=xml  use the "id" field, not the "altid" field.


Copy the script to your cacti/scripts/ directory and make it executable, then import the templates via the cacti web interface.

Graph Features:
* Sensor graphs have a red/green "status bar" across the bottom indicating the armed/disarmed status of the sensor
* Thermostat and Room Environmental graphs change background depending on time of day

Tested with the following equipment:
* Veralite
* HSM100-S3 Motion, Temperature, Light sensors
* Everspring door/window contact sensor
* Trane Thermostat

Will most likely work with others of the same types

Provides the following graphs:
* Room environmental data: Tripped/Armed status, Temperature, Light Level, Battery Level
* Thermostat: Heat Point, Cool Point, Temperature, Heat/Cool On
* Contact Sensor: Tripped/Armed status


btcguild/get_btcguild.py
---------------------
Cacti script to get your BTC's hooked up to the graphing machines!

* For use with the cacti_host_template_btcguild* files in the btcguild/templates/ directory
* You will need to supply your BTCGuild API Key when you create graphs, available here: https://www.btcguild.com/index.php?page=account

Copy the script to your cacti/scripts/ directory and make it executable, then import the templates via the cacti web interface.

Provides the following graphs:
* 24hr Rewards
* Total Rewards
* Pool Speed
* Your Speed
* Share Statistics
* Difficulty
