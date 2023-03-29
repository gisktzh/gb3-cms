#!/bin/bash
cron && apache2-foreground

# Default grav cms directory
DEFAULT_GRAV_DIR="/var/www/html/user"

# set default files location to first argument of invocation
DEFAULT_FILES_LOCATION="$1"

# Array of default files which should be moved.
# Each entry is a string with two parts, delimited by a ";":
# - [0] is the default file, relative to DEFAULT_FILES_LOCATION
# - [1] is the target directory to where the file should be moved, relative to DEFAULT_GRAV_DIR
DEFAULT_FILES=(
  "accounts/admin.yaml;accounts"
  "accounts/maintainer.yaml;accounts"
  "accounts/writer.yaml;accounts"
  "data/flex-objects/topics.json;data/flex-objects"
)

cat << "EOF"

                           *     .--.
                                / /  `
               +               | |
                      '         \ \__,
                  *          +   '--'  *
                      +   /\
         +              .'  '.   *
                *      /======\      +
                      ;:.  _   ;
                      |:. (_)  |
                      |:.  _   |
            +         |:. (_)  |          *
                      ;:.      ;
                    .' \:.    / `.
                   / .-'':._.'`-. \
                   |/    /||\    \|
                 _..--"""````"""--.._
           _.-'``                    ``'-._
         -'                                '-

EOF
echo "Initializing GravCMS!"
echo -e "Check for missing default files...\n"

# shellcheck disable=SC2164
cd "$DEFAULT_GRAV_DIR"

# Check whether the files exist, else copy them
for file in "${DEFAULT_FILES[@]}"; do
  IFS=';' read -r -a current_file <<< "$file"
  echo "=> Checking if ${current_file[0]} exists..."

  if ! test -f "${current_file[0]}"; then
    echo "==> File does not exist, copying..."
    echo "==> Copying: $DEFAULT_FILES_LOCATION${current_file[0]}" "${current_file[1]}"
    [ -d "${current_file[1]}" ] || echo "==> Creating directory which is missing..." && mkdir "${current_file[1]}"
    cp "$DEFAULT_FILES_LOCATION${current_file[0]}" "${current_file[1]}"
    echo "==> Copied file!"
  else
    echo "==> File exists, continuing..."
  fi

  echo ""
done

# Set ownership once again to overwrite root user when using bind mounts
echo "Running CHMOD on user directory again..."
chown -R www-data:www-data /var/www/html/user

# start the actual application
echo -e "We are good to go, booting GravCMS now! (つ -‘ _ ‘- )つ\n"
cron && apache2-foreground