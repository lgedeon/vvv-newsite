vvv-newsite
===========

Create a new site or sites inside Varying Vagrant Vagrants

This is now at first stable release. It works!

Still todo:
Restart nginx? at end of setup. Need to pull in the new local-nginx.conf. This is not a blocker because everything works fine ater a restart, but we can do better.
Split provision-post.sh up into:
- a core file that does the setup - reads definitions from a file
- an interactive script that builds a file with site definitions
-- note: site definition file can also be written by hand.
