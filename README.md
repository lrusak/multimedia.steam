# multimedia.steam

Initial Steam support for OpenELEC

Currently i386 only until Valve gets their **** together.

### Instructions

1. Clone OpenELEC main repo (or other)

	$ git clone https://github.com/OpenELEC/OpenELEC.tv.git

2. Change working directory

	$ cd OpenELEC.tv

3. Add submodule to OpenELEC tree

	$ git submodule add https://github.com/lrusak/multimedia.steam.git packages/addons/multimedia

4. Build addon

	$ PROJECT=Generic ARCH=i386 ./scripts/create_addon steam
