# This file is built to be run at the end of vagrant-local/provision/provision.sh
# If provision.sh doesn't call this file, set up will add the call to the
# end of the file.

# Dev Note: can append call to the end of file, but it would be even cooler
# if we could insert before "Provisioning complete" notice.

# Capture a basic ping result to Google's primary DNS server to determine if
# outside access is available to us. If this does not reply after 2 attempts,
# we try one of Level3's DNS servers as well. If neither of these IPs replies to
# a ping, we will just shut down. This script needs a network connection to
# install and update the requested copies of WordPress.
ping_result=`ping -c 2 8.8.4.4 2>&1`
if [[ $ping_result != *bytes?from* ]]
then
	ping_result=`ping -c 2 4.2.2.2 2>&1`
fi

if [[ $ping_result != *bytes?from* ]]
then
	echo "Additional sites not installed or updated. No network connection found.
	exit 0
fi

# This script will read in the content of provision-sitelist.sh which will be
# built or appended to by parse.sh. It will be in this format:
###################################
	newsite_key[1]=1
	newsite_url[1]=newsite.dev
	newsite_dir[1]=newsite_dev
	newsite_db[1]=${newsite_dir[1]}
	newsite_ver[1]=latest
	newsite_title[1]="${newsite_url[1]} version:${newsite_ver[1]}"

	newsite_key[2]=2
	newsite_url[2]=oldsite.dev
	newsite_dir[2]=oldsite_dev
	newsite_db[2]=${newsite_dir[2]}
	newsite_ver[2]=latest
	newsite_title[2]="${newsite_url[2]} version:${newsite_ver[2]}"


###################################

for key in "${newsite_key[@]}"
do
    # Install and configure the latest stable version of WordPress
    if [ ! -d /srv/www/${newsite_url[$key]} ]
    then
        echo "Downloading WordPress ${newsite_ver[$key]}, see http://wordpress.org/"
        cd /srv/www/
        if [ ${newsite_ver[$key]} == Stable ]
        then
            curl -O http://wordpress.org/latest.tar.gz
            tar -xvf latest.tar.gz
            mv wordpress ${newsite_dir[$key]}
            rm latest.tar.gz
        elif [ ${newsite_ver[$key]} == trunk ]
        then
            svn checkout http://core.svn.wordpress.org/trunk/ /srv/www/${newsite_dir[$key]}
        else
            curl -O http://wordpress.org/wordpress-${newsite_ver[$key]}.tar.gz
            tar -xvf wordpress-${newsite_ver[$key]}.tar.gz
            mv wordpress ${newsite_dir[$key]}
            rm wordpress-${newsite_ver[$key]}.tar.gz
        fi
        cd /srv/www/${newsite_dir[$key]}
        echo "Configuring WordPress ${newsite_ver[$key]}..."
        wp core config --dbname=${newsite_db[$key]} --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
define( 'WP_DEBUG', true );
PHP
        wp core install --url=${newsite_url[$key]} --quiet --title=${newsite_title[$key]} --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
    else
        if [[ ${newsite_ver[$key]} == Stable ]]
        then
            echo "Updating WordPress Stable..."
            cd /srv/www/wordpress-default
            wp core upgrade
        elif [[ ${newsite_ver[$key]} == trunk ]]
        then
            echo "Updating WordPress trunk..."
            cd /srv/www/wordpress-trunk
            svn up --ignore-externals
        fi
    fi

    if ! grep -q "${newsite_url[$key]}" /etc/hosts
    then
        DOMAINS+=" ${newsite_url[$key]}"
    fi

    if ! grep -q "${newsite_url[$key]}" /srv/config/nginx-config/sites/local-nginx.conf
    then
    cat << CONFIG >> /srv/config/nginx-config/sites/local-nginx.conf
server {
listen       80;
listen       443 ssl;
server_name  ${newsite_url[$key]};
root         /srv/www/${newsite_dir[$key]};
include /etc/nginx/nginx-wp-common.conf;
}
CONFIG
    fi
done
