################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

import os
import sys
import time
import xbmc
import xbmcaddon
import subprocess
import xbmcgui

__scriptname__ = "Steam"
__author__     = "OpenELEC"
__url__        = "http://www.openelec.tv"
__addon__      = xbmcaddon.Addon()
__addonid__    = __addon__.getAddonInfo('id')
__cwd__        = __addon__.getAddonInfo('path')

def pauseXbmc():
  xbmc.executebuiltin("PlayerControl(Stop)")
  xbmc.audioSuspend()
  xbmc.enableNavSounds(False)  
  time.sleep(1)

def startSteam():
  __launch__ = os.path.join( __cwd__, 'bin')
  subprocess.Popen('chmod +x ' + __launch__ + '/steam_openelec.sh', shell=True)
  subprocess.Popen('chmod +x ' + __launch__ + '/install_flash.sh', shell=True)

  try:
    sys.argv[1]
  except IndexError:
    if __addon__.getSetting('steamos_mode_enable') == 'true':
      p = subprocess.Popen(__launch__ + '/steam_openelec.sh steamos', shell=True)
    elif __addon__.getSetting('big_picture_mode_enable') == 'true':
      p = subprocess.Popen(__launch__ + '/steam_openelec.sh bigpicture', shell=True)
    else:
      p = subprocess.Popen(__launch__ + '/steam_openelec.sh windowed', shell=True)
  else:
     if sys.argv[1] == 'reset':
       if xbmcgui.Dialog().yesno("Steam", "Are you sure you want to reset Steam?", "Your games will not be removed", "Launch Steam again after reseting"): 
         p = subprocess.Popen(__launch__ + '/steam_openelec.sh reset', shell=True)

  p.wait()

def resumeXbmc():
  xbmc.audioResume()
  xbmc.enableNavSounds(True)

pauseXbmc()
startSteam()
resumeXbmc()

