#!/bin/bash

# Default grav cms directory
DEFAULT_GRAV_DIR="/cms_data"

# set default files/folders location to first argument of invocation
DEFAULT_FILES_LOCATION="$1"

# Array of default directories which should be created.
DEFAULT_DIRECTORIES=(
  "apache2"
  "assets"
  "backup"
  "logs"
  "user"
)

# Array of default files which should be moved.
# Each entry is a string with two parts, delimited by a ";":
# - [0] is the default file, relative to DEFAULT_FILES_LOCATION
# - [1] is the target directory to where the file should be moved, relative to DEFAULT_GRAV_DIR
DEFAULT_FILES=(
  "user/accounts/admin.yaml;user/accounts"
  "user/accounts/maintainer.yaml;user/accounts"
  "user/accounts/writer.yaml;user/accounts"
  "user/data/flex-objects/topics.json;user/data/flex-objects"
  "user/pages/01.startpage/default.md;user/pages/01.startpage"
  "user/pages/02.discovermaps/discovermaps.md;user/pages/02.discovermaps"
  "user/pages/03.pageinfos/pageinfos.md;user/pages/03.pageinfos"
  "user/pages/04.mapinfos/mapinfos.md;user/pages/04.mapinfos"
  "user/pages/05.frequentlyused/frequentlyused.md;user/pages/05.frequentlyused"
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

# shellcheck disable=SC2164
cd "$DEFAULT_GRAV_DIR"

# Check whether the directories exist, else create them
echo -e "Check for missing default directories...\n"
for directory in "${DEFAULT_DIRECTORIES[@]}"; do
  echo "=> Checking if directory ${directory} exists..."

  if ! test -d "${directory}"; then
    echo "==> Directory does not exist, creating..."
    mkdir "${directory}"
    echo "==> Setting access rights..."
    chown -R www-data:www-data "${directory}"
    echo "==> Directory created!"
  else
    echo "==> Directory exists, continuing..."
  fi

  echo ""
done

# Check whether the files exist, else copy them
echo -e "Check for missing default files...\n"
for file in "${DEFAULT_FILES[@]}"; do
  IFS=';' read -r -a current_file <<< "$file"
  echo "=> Checking if ${current_file[0]} exists..."

  if ! test -f "${current_file[0]}"; then
    echo "==> File does not exist, copying..."
    echo "==> Copying: $DEFAULT_FILES_LOCATION${current_file[0]}" "${current_file[1]}"
    [ -d "${current_file[1]}" ] || echo "==> Creating directory which is missing..." && mkdir "${current_file[1]}"
    cp "$DEFAULT_FILES_LOCATION${current_file[0]}" "${current_file[1]}"
    echo "==> Setting access rights..."
    chown -R www-data:www-data "${current_file[1]}"
    echo "==> Copied file!"
  else
    echo "==> File exists, continuing..."
  fi

  echo ""
done

# Set ownership once again to overwrite root in all directories when using bind mounts
echo "Running CHMOD on all directories again..."
for directory in "${DEFAULT_DIRECTORIES[@]}"; do
  echo "=> ${DEFAULT_GRAV_DIR}/${directory}"
  chown -R www-data:www-data "${DEFAULT_GRAV_DIR}/${directory}"
done
echo ""

# start the actual application
echo -e "We are good to go, booting GravCMS now! (つ -‘ _ ‘- )つ\n"
cron && apache2-foreground