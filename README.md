vvv-newsite
===========

Create a new site or sites inside Varying Vagrant Vagrants

This is now at first stable release. With caveats.

Has to be run using vagrant provision, but then needs to be edited so that it doesn't try to recreate the sites. I should have made the script create provision-post.sh not be it. (more under todos).

Still todo:
Script needs to be refactored to run stand-alone from command line instead of in the middle of provisioning. It should create/append only the parts that need to be in provision-post.sh and do the rest only once. Still not sure if it is more helpful to run inside vagrant or from host.
Restart nginx? at end of setup. Need to pull in the new local-nginx.conf. This is not a blocker because everything works fine after a restart, but we can do better.
Split provision-post.sh up into:
- a core file that does the setup - reads definitions from a file
- an interactive script that builds a file with site definitions
-- note: site definition file can also be written by hand.
