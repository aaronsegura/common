#!/usr/bin/python

import requests, argparse, json, sys, time, socket

class MCVError(Exception):
  def __init__(self, value):
    self.msg = value
  def __str__(self):
    return self.msg

class MiCasaVerde():
  def __init__(self, host, port, dev_id, sensorTripTimeout=None):
    self.status = None
    self.sdata = None
    self.hasChildren = False
    self.childrenData = {}
    self.host = host
    self.port = port
    self.dev_id = dev_id
    self.tripTimeout = sensorTripTimeout
    self.devices = {}
    self.updateStatus()

  def updateStatus(self):
    try:
      self.status = json.loads(self.query("status","DeviceNum=%s" % self.dev_id).content)
      self.sdata  = json.loads(self.query("sdata").content)
    except MCVError:
      raise
    except (ValueError, TypeError), err:
      raise MCVError(" %s" % err.message)
#    print "status %s" % self.status
    for dev in self.sdata["devices"]:
      devid = dev.pop("id")
      self.devices[devid] = {}

      if "parent" in dev and dev["parent"] == self.dev_id:
        self.hasChildren = True

      for key in dev.keys():
        self.devices[devid][key] = dev[key]

        # Also set/enrich parent node with additional attributes like humidity and temperature, for Aeotec ZW100 6-in-1 sensor 
        # Hopefully this does not break anything
        words_to_skip = ["id","altid","name","category","parent","subcategory","room"]
        if devid != 1 and key not in words_to_skip and "parent" in dev and dev["parent"] == self.dev_id:
          self.childrenData[key] = dev[key]
        

      # Load dictionary with values associated to each service-variable.  Including service name since some variables are duplicated
      devstatus = self.status["Device_Num_%s" % self.dev_id]["states"]
      for state in devstatus:
         try:
           self.devices[devid]["%s_%s" % (state["service"],state["variable"])] = state["value"]
         except:
           pass

      # Handle Thermostat Special Variables
      if self.devices[devid]["category"] == 5:
        if self.devices[devid]["hvacstate"] == "Heating":
          self.devices[devid]["heating"] = 1
          self.devices[devid]["cooling"] = 0

        if self.devices[devid]["hvacstate"] == "Cooling":
          self.devices[devid]["heating"] = 0
          self.devices[devid]["cooling"] = 1

        if self.devices[devid]["hvacstate"] == "Idle":
          self.devices[devid]["heating"] = 0
          self.devices[devid]["cooling"] = 0

      # Handle Contact Sensor Special Variables
      if self.devices[devid]["category"] == 4:
        if self.tripTimeout:
          now = int(time.time())
          try:
            self.devices[devid]["lasttrip"] = int(self.devices[devid]["lasttrip"])
            if self.devices[devid]["lasttrip"] > (now - self.tripTimeout):
              self.devices[devid]["tripped"] = 1
          except (KeyError, ValueError):
            pass

    # Add enriched parent data for Aeotec ZW100
    self.devices[self.dev_id].update(self.childrenData)

    return

  def query(self, queryid, addArgs=None):
    result = None
    try:
      URL = "http://%s:%s/data_request?id=%s&output_format=json" % (self.host, self.port, queryid)
      if addArgs:
        URL = "%s&%s" % (URL, addArgs)
      result = requests.get(URL)
    except requests.ConnectionError, err:
      raise MCVError("Could not connect: %s" % err.message)
    except requests.HTTPError, err:
      raise MCVError("Invalid HTTP Response: %s" % err.message)
    except (requests.Timeout, socket.timeout), err:
      raise MCVError("Timed out connecting")

    return result

def parseArgs():

  parser = argparse.ArgumentParser(description="Tool to pull statistics cacti statistics from MiCasaVerde")
  parser.add_argument("--host",  metavar="<address>", help="The IP Address of your MiCasaVerde controller", required=True)
  parser.add_argument("--port",  metavar="<port>", help="The port of the API.  [default=3480]", default=3480)
  parser.add_argument("--id",    type=int, metavar="<id>", help="MiCasaVerde Device ID", required=True)
  parser.add_argument("--freq",  type=int, metavar="<Poller Freq>", help="Cacti Poller Interval, in seconds. [Default=60]", default=60)
  parser.add_argument("--items", metavar="<xx,xx,..>", help="List of items, comma separated", required=True)

  return parser.parse_args()


def main():

  args = parseArgs()

  try:
    MCV = MiCasaVerde(args.host, args.port, args.id, sensorTripTimeout=args.freq)
  except MCVError, err:
    print "%s" % err.msg
    return

  valueMap = {
    2:  { "lv": "level"   },        # Dimmable Light
    3:  { "st": "status",           # Switch
          "kw": "kwh",
          "wt": "watts" },
    4:  { "bt": "batterylevel",     # Sensor
          "tp": "temperature",
          "lt": "light",
          "hd": "humidity",
          "tr": "tripped",
          "ar": "armed" },
    5:  { "ht": "heat",          # Thermostat
          "cl": "cool",
          "hs": "urn:upnp-org:serviceId:TemperatureSetpoint1_Heat_CurrentSetpoint",
          "cs": "urn:upnp-org:serviceId:TemperatureSetpoint1_Cool_CurrentSetpoint",
          "tp": "urn:upnp-org:serviceId:TemperatureSensor1_CurrentTemperature"}
  }

  pad = ''
  for item in args.items.split(","):
    category = MCV.devices[args.id]["category"];
    if item in valueMap[category].keys():
      sys.stdout.write("%s%s:%s" % ( pad, item, MCV.devices[args.id][valueMap[category][item]]))
      pad = ' '

if __name__ == "__main__":
  try:
    main()
  except KeyboardInterrupt:
    print "CTRL-C"

