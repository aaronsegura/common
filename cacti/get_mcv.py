#!/usr/bin/python

import requests, argparse, json, sys

class MCVError(Exception):
  def __init__(self, value):
    self.msg = value
  def __str__(self):
    return self.msg

class MiCasaVerde():
  def __init__(self, host, port):
    self.status = None
    self.sdata = None
    self.host = host
    self.port = port
    self.devices = {}
    self.updateStatus()

  def updateStatus(self):
    try:
      self.status = json.loads(self.query("status").content)
      self.sdata  = json.loads(self.query("sdata").content)
    except MCVError:
      raise
    except (ValueError, TypeError), err:
      raise MCVError(" %s" % err.message)

    for dev in self.sdata["devices"]:
      devid = dev.pop("id")
      self.devices[devid] = {}

      for key in dev.keys():
        self.devices[devid][key] = dev[key]

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

    return

  def query(self, queryid, addArgs=None):
    result = None
    try:
      URL = "http://%s:%s/data_request?id=%s&output_format=json" % (self.host, self.port, queryid)
      if addArgs:
        URL = "%s&%s" (URL, addArgs)
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
  parser.add_argument("--items", metavar="<xx,xx,..>", help="List of items, comma separated", required=True)

  return parser.parse_args()


def main():

  args = parseArgs()

  try:
    MCV = MiCasaVerde(args.host, args.port)
  except MCVError, err:
    print "%s" % err.msg
    return

  valueMap = {
    2:  { "lv": "level"   },        # Dimmable Light
    3:  { "st": "status"  },        # Switch
    4:  { "bt": "batterylevel",     # Sensor
          "tp": "temperature",
          "lt": "light",
          "tr": "tripped" },
    5:  { "ht": "heating",          # Thermostat
          "cl": "cooling",
          "hs": "heatsp",
          "cs": "coolsp",
          "tp": "temperature"}
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

