import dbus, glib
from dbus.mainloop.glib import DBusGMainLoop

DBusGMainLoop(set_as_default=True)
self.bus = dbus.SystemBus()

self.bus.add_match_string("interface='org.freedesktop.Networkmanager', eavesdrop='true'")

mainloop = glib.MainLoop()
mainloop.run()

