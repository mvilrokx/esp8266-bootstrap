## Files

### init.lua
When you boot the the nodeMCU board, it will auto-run the file with the name 'init.lua'.  If this file does not exists, the boot sequence will end and manual intervention is required to start running another lua script. Because we want our nodeMCU to boot straight into our application, we need an init.lua script that autostarts our application.

We want to keep this file as small as possible because it cannot be compiled into an .lc file (the board will not autorun init.lc).

The purpose of init.lua is 3-fold:

1. Prevent an infinite loop sequence
2. Set the board into STATIONAP mode (a mix of Access Point and Station)
3. Launch either your application if you have configured the board already (using this tool) or the config mode that allows you to set this up

In init.lua we introduce a boot delay (in seconds).  You can use this delay to halt the boot sequence by sending a tmr.stop(0) command to the board.  The purpose of this is to prevent an infinite reboot loop, which occurs if an error gets raised during the boot sequence.

After this delay, init.lua will look for a file called config.lua.  If it cannot find this file, it will go into config mode and launch a file called configure.lc.  If it does find config.lua, it will run that file.  This file contains lua global variables that can be used in your application.  One of these global variables is called bootFile and it should contain the application root file.  If this variable is not found or not set, init.lua reverts back to config mode where you can set this file.  If it is found, init.lua launches this file, effectively starting your application.

### configure.lua
This file gets run when the board is in config mode.  This can happen several different ways:

* config.lua does not exist, i.e. you have not configured the board yet with this tool
* config.lua does exist, but it does not contain a bootFile
* the user connects pin 3 to GND during the boot sequence, this launches the board in config mode, regardless of previous settings.  This allows you to override previous config settings

When run, it creates a web server that you can connect to (using a browser) to start configuring the board for your application.  You can connect to this server by connecting to the Access Point that init.lua created on boot.  This AP can be identified by it's name that starts with "ESP-" and then a number (which is the node.chipid()), e.g. ESP-12345678.  Once you are connected to your ESP, point your browser to 192.168.4.1 and you will be presented by the config page.  This config page is contained in index.html (see next)

### index.html
This file contains all the HTML, CSS and JS that you see when you open the config page in your browser.  It gets served when you connect to the board, the board is in config mode and you point your browser to 192.168.4.1.

There are 5 fields on the config page, you can set each one to configure the board for your application.

#### Boot Delay
This field controls the delay (in seconds) that gets applied to the boot time.  The higher this number, the longer it takes to boot the board and the more time users will have to either stop boot or launch into config mode (see init.lua for more information)

#### WiFi Mode
Use this field to set the WiFi mode your board boots into, you can choose wifi.STATIONAP which sets the board up to be both an Access Point (that you can then connect to) and a wifi station (that can itself connect to another network).  You would typically use this mode if you want to access your board directly AND you want to connect the board to the internet.  wifi.SOFTAP is used if you want your board to only be an access point.  wifi.STATION is used to configure your board to connect to another Access Point (e.g. your router, which then connects it to the internet).  You can also pick None which means you will not be using your ESP as an IoT device but just as a GPIO input/output device.

Depending on what you pick, the following fields might be available or not.

#### Network (aka SSID)
This field will list all the available Access Points that the board can connect to.  Note that this will **not** show 5GHz wifi networks as the esp chip cannot connect to those networks.  This field will not be visible if you pick "None" or SOFTAP as the Wifi Mode as neither of those require a connection to an Access Point.

#### Password
This is the password you need to connect to the network you picked in the previous field.  Like the network field, this field will not be visible if you pick "None" or SOFTAP as the Wifi Mode as neither of those require a connection to an Access Point.  It will also not be visible if the network you selected does not require a password.

#### Boot File
This list allow you to select a file that you want to launch at startup of the board (after init.lua).  Effectively this is your application that you want the board to run.  The list contains all the files that are present on the board (so you need to load you application files on the board first) minus all the files that come as part of this framework.

## Framework
In order to be able to serve web pages and json (like index.html) effectively and efficiently and to overcome some of the limitations of the board, I had to create a micro framework that includes a router and a web server among other things.  You can use these yourself if you want your application to serve html or json.  Due to the limitations of the board, these utilities are kept to the absolute minimum, e.g. the web server only responds to POST and GET requests and not PATCH, PUT etc.  Everything has been done to keep the heap usage at a minimum.

### Usage
The easiest way to understand how to use the framework is to look at the how it is being used by the configuration tool that is included, specifically look at configure.lua and routes.lua, more on those later.

The framework is (loosely) based on Express and likeminded frameworks; you create routes that respond to requests.  These responses are the html or json that you want to send to the clients in response to their requests.  It really doesn't matter how the response is created, as long as it is a string that we can send back.  Lets start by looking at the configure.lua file and how it is using routes.

### configure.lua
You would start by copying and modifying this file for our usage.  The first part of this file instanciates a router.  It needs routes to be able to do this.  These routes live in the routes.lc file for the configurator and so that file gets run first, then the new router gets initiated using those routes.

Next the server gets started, it starts listening (on port 80) and when it receive a request it dispatches this request to the just created router.  The route has to return a header and a body, the receive event then response with the header and finishes, i.e. it does not send the body, this happens later.  The reasons for this are that the board can only send out 512 bytes at a time and so the response has to be split up in 512 byte-sized chunks.  Unfortunately, "send" on the connection object is an asynchronous event and so calling this multiple times in a row with the chunks will cause the board to freeze and reboot as it tries to work it's way through these queued send commands (the heap will overflow and crash the board).  The only way to avoid this is wait till the first send has finished and only then perform the second send.  And the way this was solved was to put all this logic in the "sent" event handler.  This gets triggered when the send command finishes, which is exactly what we need.

The first time it gets called is when the header is sent (which is why that part was sent in the receive event handler, to trigger the sent event a first time).  In that same sent event handler, we then check if there is a body that needs to be send.  If there is, we read the first 512 bytes and send those.  We also store a "file pointer" in a global variable that persists between sending.  This file pointer indicates what we have sent so far.  As soon as that send command completes, it calls the sent event handler again, which starts reading the next 512 bytes and send them, repeating the process until all bytes of the file have been sent.

### routes.lua
This file contains the routes of the config application.  You can add your own routes if you want.  You add an entry for your path (e.g. /home) and HTTP verb (e.g. POST) within that path.  You assign a function to that entry, which is what will get called if that path and that HTTP verb are being requested by the client from the server.  The function MUST return a LUA table that contains a header key which has as value a valid HTTP Header.  It can also contain a body key with either a file name or a data field that contains JSON data to be send back to the client.

If you remove the entries already present, the config app will stop working so please only add new routes.
