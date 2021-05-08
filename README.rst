==============
packet_vmt.lua
==============

About
======

`packet_vmt.lua`_ is a `Wireshark Plugin`_ for `Virtual Motion Tracker`_ packet dissection.

.. _`packet_vmt.lua`: /src/packet_vmt.lua
.. _`Virtual Motion Tracker`: https://github.com/gpsnmeajp/VirtualMotionTracker
.. _`Wireshark Plugin`: https://wiki.wireshark.org/Lua

How it works
============

under construction

Setting up
==========

1. Place the configuration file
--------------------------------

Place ``packet_vmt.lua`` in ``src`` folder to your Wireshark's user script folder.
Usualy the folder is ``C:\Users\<Your_User_ID>\AppData\Roaming``.

The below PowerShell command can help you to place the script in this folder.

::

    Copy-Item ./src/packet_vmt.lua $env:APPDATA/Wireshark/plugins

After this placement, you should reload the script folder by (Analyze->Reload Lua Plugins; Ctrl-Shift-L) button.

1. Check your enviroment
---------------------------

A python script ``test_packet_vmp.py`` in ``test`` folder can generate VMT messages which cover all type of VMT for a test.
You can check your environment with this test script. 
``test_packet_vmp.py`` requires three args options which are the IP address of the driver working on, VMT driver listening port number, and VMT manager listening port.
Usualy, the driver and manager port numbers are 39570 and 39571 each other.
If you are using Visual Studio Code, `launch.json`_ is useful to lunch this test script on Python mode.
When you use this file, you should modify IP address and port numbers for your enviroment.

.. _`launch.json`: https://wiki.wireshark.org/Lua

How to use
==========

under construction

License
=======

Copyright (c) 2021, `A.Shiomaneki`_

This program is released under the MIT License.
See `LICENSE`_ for the troposphere full license text.

.. _`LICENSE`: http://opensource.org/licenses/mit-license.php
.. _`A.Shiomaneki`: https://potofu.me/beach-of-ashiomaneki