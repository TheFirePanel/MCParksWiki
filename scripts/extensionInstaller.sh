#!/bin/bash
DIR="/var/www/html"
cd $DIR # Make sure we are set in the correct wd

# All extensions to add, [GIT URL]="BRANCH"
declare -A repos=(
    ["https://github.com/jayktaylor/mw-discord"]="REL1_35"
    ["https://github.com/edwardspec/mediawiki-aws-s3"]="master"
    ["https://github.com/StarCitizenTools/mediawiki-extensions-TabberNeue"]="main"
    ["https://gerrit.wikimedia.org/r/mediawiki/extensions/Disambiguator"]="REL1_46"
    ["https://gerrit.wikimedia.org/r/mediawiki/extensions/MobileFrontend"]="REL1_46"
    ["https://gerrit.wikimedia.org/r/mediawiki/extensions/TemplateStyles"]="REL1_46"
)

# Go into extensions directory
cd $DIR/extensions/
for repo in "${!repos[@]}"; do
    branch=${repos[$repo]}
    
    echo "Cloning $repo (branch: $branch)"
    git clone --depth 1 --single-branch --branch $branch $repo

    IFS='/' read -ra VAL <<< "$repo"
    chown -R www-data:www-data ${VAL[-1]}
done

## Update/Install extension dependencies
# Delete problem child composer files
IGNORE_COMPOSER=()
for ext in "${IGNORE_COMPOSER[@]}"; do
    rm $DIR/extensions/$ext/composer.json
done

# Run the actual composer command
cd $DIR
echo "Running composer update in $DIR"
COMPOSER_ALLOW_SUPERUSER=1 composer update --prefer-dist --no-dev
rm -rf /root/.composer # Remove composer cache
