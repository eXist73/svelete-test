#!/usr/bin/env bash

set -e # Exit script immediately on first error.
set -x # Print commands and their arguments as they are executed.

# Copy the sites to the nginx directory
sudo cp /vagrant/default /etc/nginx/sites-available

# Import the configuration file
source /vagrant/config.cfg

# add laravel cron jobs
crontab -l | { cat; echo "* * * * * php /var/www/html/artisan schedule:run"; } | crontab -

# Add our site routes to the virtual /etc/hosts file
echo "127.0.1.1 $site_web" | sudo tee -a /etc/hosts

# Edit the server config to update the web server
sed -i -e "s/site_web/$site_web/g" /etc/nginx/sites-available/default

# Enable the site
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Touch the log files to make sure they exist
sudo touch /var/www/log/nginx.access.log
sudo touch /var/www/log/nginx.error.log

# Make sure composer is installed
if [ -f '/var/www/html/.env' ] && ! [ -d '/var/www/html/vendor' ]
then
    cd /var/www/html
    sudo composer install
fi

# Create symbolic link for local file upload viewing
if [ -f '/var/www/html/.env' ] && ! [ -L '/var/www/html/public/storage' ]
then
    # Enable permission for laravel specific folders
    sudo chmod -R 775 /var/www/html/storage/*

    # Create symbolic link for public storage locally
    sudo ln -s /var/www/html/storage/app/public /var/www/html/public/storage
fi

# Enable permissions on log folders
sudo chmod -R 775 /var/www/log

# Add aliases to BASH RC HERE
if ! grep -q '#VAGRANT_ALIAS' /home/vagrant/.bashrc; then
sudo sh -c "cat >> /home/vagrant/.bashrc" <<'EOF'
#VAGRANT_ALIAS - From provision.sh
alias gosql="mysql -uhomestead -psecret homestead"
alias put="cd /var/www/html && ./vendor/bin/phpunit"
EOF
fi

# Migrate / Seed the DB
if [ -f '/var/www/html/.env' ]
then
    cd /var/www/html
    php artisan migrate:fresh --seed
else
    echo 'Create a new project with: vagrant ssh -c "composer create-project --prefer-dist laravel/laravel /var/www/html"'
    echo "If on windows you may need to downgrade NPM: sudo npm install -g npm@5.7.1"
fi

# Restart the nginx service to show enabled sites
sudo service nginx restart
