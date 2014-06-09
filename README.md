multimedia.steam
================

Initial Steam support for OpenELEC

Currently i386 only until Valve gets their **** together.

git clone https://github.com/OpenELEC/OpenELEC.tv.git

cd OpenELEC.tv

git submodule add https://github.com/lrusak/multimedia.steam.git packages/addons/multimedia

PROJECT=Generic ARCH=i386 ./scripts/create_addon steam
