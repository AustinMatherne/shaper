Shaper
======

Shaper is a shell script for controlling the Linux Traffic Control utility.


Requirements
------------

TC (the convoluted utility Shaper controls) requires certain options within the
Linux kernel be enabled. I run it on my own custom configured kernel and make no
promises to its ability to run on stock kernels provided by other distros;
however, I would be rather surprised if it didn't work. Open an issue if you
have any issues, and I'll try to get it working for you.


Usage
-----
Example: sudo ./shaper.sh -a start -i eth0 -d 5120 -u 1000 -l 1 -r kbit -t sec

In the example above device eth0 is limited to downloading 5120 kilobits per
second with a half second of latency and uploading 1000 kilobits per second with
an additional half second of latency. The half second of upload latency with the
other half second of download latency combines for one full second of practical
latency which is represented above as "-l 1".

Note, Shaper is currently limited to shaping one device at a time.


OPTIONS:

*  -h   Show this message.
*  -a   The action to take ("-a start", "-a stop", "-a restart", "-a show").
*  -i   Interface name to shape ("-i eth0", "-i lo").
*  -d   Maximum download speed in mbits ("-d 5" is 5mbit).
*  -u   Maximum upload speed in Mbits ("-u 2" is 2mbit).
*  -l   Latency to add ("-l 50" split over upload and download, totaling 50ms).
*  -r   Rate at which download and upload options operate, defaults to mbit.
*  -t   Scale at which latency option operates, defaults to ms.

