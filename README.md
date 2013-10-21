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

Project map:
- build.sh - creates a {$project}.json or {$project}.sh file that identifies the sites we want to set up, sql-dumps of content for those sites (optional), media.zip content to populate the media library (optional)
- parse.sh - included in a zipped folder with the sql, media, and {$project} file above.
-- Reads the {$project} file and puts sql and media files in correct place
-- Creates provision-post.sh if it is not already present.
-- Adds new sites to a file in provisions folder that is read by provision-post.sh
-- Adds new sites to:
--- /config/nginx-config/sites/local-nginx.conf
--- /database/init-custom.sql
--- vagrant's host file
--- the host OS hosts file
- dropparse.sh (placeholder name) calls parse.sh from inside vagrant on vagrant up, if there is anything in the import folder that needs to be processed. Will need some way to check to see if a particular import has already been run.
