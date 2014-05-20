#
# Python script to interact with switchAPI
#
#    Aaron Segura x501-5895
#
import sys
import getpass
import urllib2
import warnings
import json
import argparse

# http://askubuntu.com/questions/116020/python-https-requests-urllib2-to-some-sites-fail-on-ubuntu-12-04-without-proxy
# Forces TLSv1 to get around bad ssl handshake shenanigoats
import functools
import ssl
old_init = ssl.SSLSocket.__init__

@functools.wraps(old_init)
def ubuntu_openssl_bug_965371(self, *args, **kwargs):
  kwargs['ssl_version'] = ssl.PROTOCOL_TLSv1
  old_init(self, *args, **kwargs)

ssl.SSLSocket.__init__ = ubuntu_openssl_bug_965371

###############################################
class SwitchAPIException(BaseException):
  pass

class SwitchAPIError(SwitchAPIException):
  def __init__(self, errormsg):
    self.msg = errormsg

  def __str__(self):
    return self.msg

###############################################
class SwitchAPI():

  def __init__(self, user=None, password=None, switchName=None, debug=0):
    self.debug       = debug
    self.log(1, "init(BEGIN)")

    if not user:
      sys.stderr.write("SSO Username: ")
      user = sys.stdin.readline().rstrip()

    if not password:
      password = getpass.getpass("Password for %s: " % (user), sys.stderr)

    if not switchName:
      raise SwitchAPIError("Switch Name not supplied.  ex: bg77-2e.dfw1")

    self.httpUser    = user
    self.httpPass    = password
    self.switchName  = switchName
    self.baseUrl     = "https://api.netsec.rackspace.net/switches/"
    self.port        = {}
    self.neighbors   = []

    # Set up urllib2 environment
    pwmgr       = urllib2.HTTPPasswordMgrWithDefaultRealm()
    pwmgr.add_password(None, uri=self.baseUrl, user=self.httpUser, passwd=self.httpPass)
    authHandler = urllib2.HTTPBasicAuthHandler(pwmgr)
    opener = urllib2.build_opener(authHandler)
    urllib2.install_opener(opener)

    warnings.filterwarnings("ignore", category=UserWarning, module='urllib2')

    self.update()
    self.log(1, "init(END)")
    return

  ###############################################
  def update(self, type=None):
    try:
      r = self.query("interfaces")
    except SwitchAPIError:
      raise
    else:
      ifaces = json.loads(r)

      for i in ifaces["items"]:
        if i["port"] != -1:
          self.port[i["port"]] = {
            "trunk": i["trunking"]["enabled"],
            "vlan_id": i["vlan_id"],
            "vlans_allowed": [],
            "mac_addresses": [],
            "admin": i["admin"],
            "link" : i["link"],
            "iface": i["id"],
            "duplex": i["duplex"],
            "speed": i["speed"],
            "type" : i["type"],
            "name" : i["name"],
            "port" : i["port"]
          }
        if "native_vlan" in i["trunking"]:
          self.port[i["port"]]["native_vlan"] = str(i["trunking"]["native_vlan"])

    try:
      r = self.query("vlans")
    except SwitchAPIError:
      raise
    else:
      vlans = json.loads(r)

      for v in vlans["items"]:
        for i in v["interface_ids"]:
          port = self.find(iface=i)
          self.port[port]["vlans_allowed"].extend([str(v["id"])])
        for m in v["mac_addresses"]:
          port = self.find(iface=m["interface_id"])
          self.port[port]["mac_addresses"].extend([m["address"]])

  ###############################################
  def query(self, subType=None, subArg=None):

    req = "%s%s" % (self.baseUrl, self.switchName)

    if subType:
      req += "/%s" % (subType)
      if subArg:
        req += "/%s" % (subArg)

    self.log(1, "swQ(Query): %s" % req)

    try:
      fp = urllib2.urlopen(req)
      r = fp.read()
    except urllib2.URLError, err:
      raise SwitchAPIError("URLError (%s): %s" % (req, err.reason))
    except urllib2.HTTPError, err:
      raise SwitchAPIError("HTTP %s Error: %s" % (err.code, err.reason))

    return r

  ###############################################
  def find(self, iface=None, mac=None, vlan=None):
    r = []

    if iface:
      for key in self.port.keys():
        if self.port[key]["iface"] == iface:
          return key

    if mac:
      for key in self.port.keys():
        if mac in self.port[key]["mac_addresses"]:
          r.extend([key])

    if vlan:
      for key in self.port.keys():
        if str(vlan) in self.port[key]["vlans_allowed"] or vlan == self.port[key]["vlan_id"]:
          r.extend([key])

    return r
  ###############################################
  def printPort(self, port, verbose=False):

    if self.port[port]["trunk"]:
      try:
        native = self.port[port]["vlans_allowed"].index(self.port[port]["native_vlan"])
      except ValueError:
        pass
      else:
        self.port[port]["vlans_allowed"][native] = "*%s*" % self.port[port]["native_vlan"]

      trunkInfo = "Trunk: %s" % " ".join(self.port[port]["vlans_allowed"])
    else:
      trunkInfo = "Access VLAN %d" % self.port[port]["vlan_id"]

    trunkInfo = "[%s]" % trunkInfo

    numAddr = len(self.port[port]["mac_addresses"])
    if numAddr == 0:
      MACInfo = "None"
    else:
      if verbose:
        MACInfo = ",".join(self.port[port]["mac_addresses"])
      else:
        if numAddr == 1:
          MACInfo = self.port[port]["mac_addresses"][0]
        else:
          MACInfo = "None/Multiple"

    MACInfo = "[%s]" % MACInfo

    print("[%d]\t%s \tlink:%s  \t[%d/%s]\t%s\t%s" % ( self.port[port]["port"], self.port[port]["admin"], self.port[port]["link"], self.port[port]["speed"], self.port[port]["duplex"], trunkInfo, MACInfo))
    #if verbose:
      #print("Port [%d]  Speed: %s, Duplex: %s  Linked: %s  Enabled: %s\n%s" % (port, self.port[port]["speed"], self.port[port]["duplex"], self.port[port]["link"], self.port[port]["admin"], trunkInfo))
      #print("Mac Addresses:\n%s" % MACInfo)
    #else:

  ###############################################
  def log(self, pri, msg):
    if self.debug >= pri:
      print("-> (%d) %s" % (pri, msg))
    return

#################################################

def main():
  parser = argparse.ArgumentParser(description="CLI SwitchTalker")

  parser.add_argument("-u", dest="userSSO", type=str, default=None, metavar="<Racker SSO>", help="Your RACKSPACE SSO")
  parser.add_argument("-s", dest="userSW", type=str, default=None, metavar="<SwitchName>", help="Switch Name")
  parser.add_argument("-p", dest="userPort", type=int, default=None, metavar="<port#>", help="Show port #")
  parser.add_argument("-m", dest="userMAC", type=str, default=None, metavar="<xx-xx-xx-xx-xx-xx>", help="Show ports with MAC Address")
  parser.add_argument("-v", dest="userVLAN", type=str, default=None, metavar="<0-4095>", help="Show ports on VLAN")

  args = parser.parse_args()

  sw = SwitchAPI(user=args.userSSO, switchName=args.userSW, debug=0)

  if args.userMAC:
    ports = sw.find(mac=args.userMAC)
    for p in ports:
      sw.printPort(p, verbose=True)

  if args.userVLAN:
    ports = sw.find(vlan=args.userVLAN)
    for p in ports:
      sw.printPort(p)

  if args.userPort:
    sw.printPort(args.userPort, verbose=True)

  if not args.userVLAN and not args.userMAC and not args.userPort:
    for n in sw.port.keys():
      sw.printPort(n)

if __name__ == '__main__':
  try:
    r = main()
  except KeyboardInterrupt:
    print "Keyboard Interrupt Caught"

  sys.exit(r)

