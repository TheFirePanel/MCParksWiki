#!/bin/bash
set -euo pipefail # Fail the image build if any step fails

DIR="/var/www/html"
cd $DIR # Make sure we are set in the correct wd

# All extensions to add, [GIT URL]="BRANCH [DIRECTORY]"
# DIRECTORY defaults to the repo name, set it when the repo name differs from the extension name
# Wikimedia extensions use their GitHub mirrors, Gerrit is unreliable from CI runners
# TemplateStyles is bundled with MediaWiki 1.46+, don't clone it here
declare -A repos=(
    ["https://github.com/jayktaylor/mw-discord"]="REL1_35"
    ["https://github.com/edwardspec/mediawiki-aws-s3"]="master"
    ["https://github.com/StarCitizenTools/mediawiki-extensions-TabberNeue"]="main"
    ["https://github.com/wikimedia/mediawiki-extensions-Disambiguator"]="REL1_46 Disambiguator"
    ["https://github.com/wikimedia/mediawiki-extensions-MobileFrontend"]="REL1_46 MobileFrontend"
)

# Go into extensions directory
cd $DIR/extensions/
for repo in "${!repos[@]}"; do
    read -r branch name <<< "${repos[$repo]}"

    if [ -z "$name" ]; then
        IFS='/' read -ra VAL <<< "$repo"
        name=${VAL[-1]}
    fi

    # Retry clones in case of transient network failures
    for attempt in 1 2 3; do
        echo "Cloning $repo into $name (branch: $branch, attempt $attempt)"
        if git clone --depth 1 --single-branch --branch $branch $repo $name; then
            break
        fi
        rm -rf $name
        if [ $attempt -eq 3 ]; then
            echo "Failed to clone $repo" >&2
            exit 1
        fi
        sleep 10
    done

    chown -R www-data:www-data $name
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
