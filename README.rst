==============
packet_vmt.lua
==============

About
======

`packet_vmt.lua`_ is a Wireshark Plugin in Lua [1]_ for Virtual Motion Tracker [2]_ packet dissection.
This plugin is developed as port-independent (heuristic) dissector [3]_ based on ``packet-osc.c`` [4]_.

.. _`packet_vmt.lua`: /src/packet_vmt.lua

How it works
============

under construction

Setting up
==========

1. Place the configuration file
--------------------------------

Place `packet_vmt.lua`_ in `src`_ folder to your Wireshark's user script folder [3]_.
Usualy the folder is ``C:\Users\<Your_User_ID>\AppData\Roaming``.

The below PowerShell command can help you to place the script in this folder.

::

    Copy-Item ./src/packet_vmt.lua $env:APPDATA/Wireshark/plugins

After this placement, you should reload the script folder by (Analyze->Reload Lua Plugins; Ctrl-Shift-L) button.

.. _`src`: /src

2. Check your enviroment
---------------------------

A python script `test_packet_vmt.py`_ in `test`_ folder can generate VMT messages which cover all type of VMT for a test.
You can check your environment with this test script. 
`test_packet_vmt.py`_ requires three args options which are the IP address of the driver working on, VMT driver listening port number, and VMT manager listening port.
Usualy, the driver and manager port numbers are 39570 and 39571 each other.
If you are using Visual Studio Code, `launch.json`_ is useful to lunch this test script on Python mode.
When you use this file, you should modify IP address and port numbers for your enviroment.

.. _`test_packet_vmt.py`: /test/test_packet_vmt.py
.. _`test`: /test
.. _`launch.json`: ./.vscode/launch.json

How to use
==========

under construction

References
==========

.. [#] Lua,
    https://wiki.wireshark.org/Lua
.. [#] VMT - Virtual Motion Tracker,
    https://github.com/gpsnmeajp/VirtualMotionTracker
.. [#] B.4. Plugin folders,
    https://www.wireshark.org/docs/wsug_html_chunked/ChPluginFolders.html
.. [#] Creating port-independent (heuristic) Wireshark dissectors in Lua,
    https://mika-s.github.io/wireshark/lua/dissector/2018/12/30/creating-port-independent-wireshark-dissectors-in-lua.html
.. [#] packet-osc.c,
    https://gitlab.com/wireshark/wireshark/-/blob/master/epan/dissectors/packet-osc.c

License
=======

Copyright (c) 2021, `A.Shiomaneki`_

This program is released under the MIT License.
See `LICENSE`_ for the troposphere full license text.

.. _`LICENSE`: http://opensource.org/licenses/mit-license.php
.. _`A.Shiomaneki`: https://potofu.me/beach-of-ashiomaneki