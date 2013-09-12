# provision.sh
#
# This file is specified in Vagrantfile and is loaded after the primary
# provisioning script whenever the commands `vagrant up`, `vagrant provision`,
# or `vagrant reload` are used. It provides additional sites specific to your
# use cases.

# By storing the date now, we can calculate the duration of provisioning at the
# end of this script.
start_seconds=`date +%s`

# Capture a basic ping result to Google's primary DNS server to determine if
# outside access is available to us. If this does not reply after 2 attempts,
# we try one of Level3's DNS servers as well. If neither of these IPs replies to
# a ping, then we'll skip a few things further in provisioning rather than
# creating a bunch of errors.
ping_result=`ping -c 2 8.8.4.4 2>&1`
if [[ $ping_result != *bytes?from* ]]
then
	ping_result=`ping -c 2 4.2.2.2 2>&1`
fi

# Capture the current IP address of the virtual machine into a variable that
# can be used when necessary throughout provisioning.
# vvv_ip=`ifconfig eth1 | ack "inet addr" | cut -d ":" -f 2 | cut -d " " -f 1`

# set up poor man's multidimensional array
# this lists all the pieces we will need for the rest of the script
	newsite_key[1]=1
	newsite_url[1]=newsite.dev
	newsite_dir[1]=${newsite_url[1]}  # I typically name the directory and db after the domain. Feel free to override.
	newsite_db[1]=${newsite_url[1]}
	newsite_ver[1]=latest
	newsite_title[1]="${newsite_url[1]} version:${newsite_ver[1]}"

	newsite_key[2]=2
	newsite_url[2]=oldsite.dev
	newsite_dir[2]=${newsite_url[2]}  # I typically name the directory and db after the domain. Feel free to override.
	newsite_db[2]=${newsite_url[2]}
	newsite_ver[2]=latest
	newsite_title[2]="${newsite_url[2]} version:${newsite_ver[2]}"

for key in "${newsite_key[@]}"
do
	echo ${newsite_key[$key]}
	echo ${newsite_url[$key]}
	echo ${newsite_dir[$key]}
	echo ${newsite_ver[$key]}
	echo ${newsite_title[$key]}
done

# create a /srv/config/nginx-config/sites/new_site.conf if one does not yet exist - we will append to it in a bit.
if [ ! -f /srv/config/nginx-config/sites/new_site.conf ]
then
	touch /srv/config/nginx-config/sites/new_site.conf
fi

# add databases to /database/init-custom.sql
if [ ! -f /srv/database/init-custom.sql ]
then
	touch /srv/database/init-custom.sql
fi

for db in "${newsite_db[@]}"
do
	if ! grep -q "$db" /srv/database/init-custom.sql
	then
	cat << SQL >> /srv/database/init-custom.sql
CREATE DATABASE IF NOT EXISTS \`$db\`;
GRANT ALL PRIVILEGES ON \`$db\`.* TO 'wp'@'localhost' IDENTIFIED BY 'wp';
SQL
	fi
done

# Run (rerun) init-custom.sql that we just added new sites to
mysql -u root -pblank < /srv/database/init-custom.sql | echo -e "\nInitial custom MySQL scripting..."


# Things I still may need to do
# cp ~/Sites/vagrant-local/config/nginx-config/sites/local-nginx-example.conf-sample ~/Sites/vagrant-local/config/nginx-config/sites/new_site.conf
# edit ~/Sites/vagrant-local/config/nginx-config/sites/seos.dev.conf
# ## edit server_name and root

# build a list of domains to add to /etc/hosts
DOMAINS=""

# Install new site specified below
if [[ $ping_result == *bytes?from* ]]
then
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
			wp core install --url=--quiet --title=${newsite_title[$key]} --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
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

	done
fi

if [[ ${#DOMAINS} > 0 ]]
then
	echo "127.0.0.1 $DOMAINS" >> /etc/hosts
	cat <<HOSTS

**************************************************
***              ACTION NEEDED                 ***
**************************************************
New domains added in vagrant. Don't forget to add them to your local hosts file!
If you are on a *nix system this should do the trick:

sudo sh -c 'echo "192.168.50.4 ${DOMAINS}" >>/private/etc/hosts'

**************************************************

HOSTS
fi

end_seconds=`date +%s`
echo "-----------------------------"
echo "Provisioning complete in `expr $end_seconds - $start_seconds` seconds"
if [[ $ping_result == *bytes?from* ]]
then
	echo "External network connection established, new sites have been installed."
else
	echo "No external network available. New site setup will have to be done later."
fi
