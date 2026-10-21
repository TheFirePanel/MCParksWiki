#!/bin/bash
## Setup environment
env >> /etc/environment

# Set cwd to MediaWiki install location
DIR="/var/www/html"
cd $DIR

# Run production tasks if we aren't debugging
if ! $DEBUG ; then
    ## LocalSettings manager
    LOCALSETTINGS_URL="https://raw.githubusercontent.com/TheFirePanel/MCParksWiki/main/LocalSettings.php"
    echo "Grabbing LocalSettings from GitHub"
    curl $LOCALSETTINGS_URL -O

    ## Sitemap
    /bin/bash -c "/scripts/generateSitemap.sh"
    # Add sitemap to robots.txt, need to do it here to get the server url
    echo -e "\nSitemap: $MW_SERVER/sitemap.xml" >> $DIR/robots.txt
fi

## Start supervisord
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
