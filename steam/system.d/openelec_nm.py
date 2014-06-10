import dbus, glib, dbus.service
from dbus.mainloop.glib import DBusGMainLoop

class MyDBUSService(dbus.service.Object):
  def __init__(self):
    bus_name = dbus.service.BusName('org.freedesktop.NetworkManager', bus=dbus.SystemBus())
    dbus.service.Object.__init__(self, dbus.SystemBus(), '/org/freedesktop/NetworkManager')

DBusGMainLoop(set_as_default=True)
myservice = MyDBUSService()

#bus = dbus.SystemBus()
#bus.add_match_string("interface='org.freedesktop.Networkmanager'")

mainloop = glib.MainLoop()
mainloop.run()

