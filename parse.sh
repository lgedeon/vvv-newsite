# parse.sh - included in a zipped folder with the sql, media, and {$project} file above.
# -- Reads the {$project} file and puts sql and media files in correct place
# -- Creates provision-post.sh if it is not already present.
# -- Adds new sites to provision-sitelist.sh that is read by provision-sites.sh
# -- Adds new sites to:
# --- /config/nginx-config/sites/local-nginx.conf
# --- /database/init-custom.sql
# --- vagrant's host file
# --- the host OS hosts file