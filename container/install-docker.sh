HOST_IDENTIFIER=$(echo $HOSTNAME | awk -F'-' '{print $NF}')
GUID=${SENTRY_GUID_PREFIX:-sonar-sentry-}$HOST_IDENTIFIER
TOKEN=`cat /etc/secrets/sentry-auth-token`
URL=$DEPLOY_URL
BASE=$BASE_HOSTNAME
RPC_PORT=7140
CONF_FILE=logpresso.conf

if [ -e /etc/secrets/sentry-auth-token ]; then
	SONAR_API_KEY=`cat /etc/secrets/sonar-api-key`
	echo "Registring Daemonset Sentry..."
	API_TARGET=${DEPLOY_URL/:44300/:$CONTROL_API_PORT}/api/sonar/sentries
	echo GUID: $GUID
	echo API_TARGET: $API_TARGET
	RESPONSE=$(curl -k -X POST "$API_TARGET" \
		-d "sentry_guid=${GUID}&auth_token=${TOKEN}&os=linux&base=$BASE" \
		-H "Authorization: Bearer ${SONAR_API_KEY}")

	echo RESPONSE: $RESPONSE
fi

function detect_os_version() {
    if [ -f "/etc/os-release" ]; then
        OS_NAME=$(grep '^ID=' /etc/os-release | awk -F=  '{gsub(/"/, "", $2); print $2 }')
        OS_VER=$(grep '^VERSION_ID=' /etc/os-release | awk -F=  '{gsub(/"/, "", $2); print $2 }')
    fi

    # for centos(display major version only)
    if [ ${#OS_VER} -eq 1 ] && [ -f "/etc/system-release" ]; then
        OS_VER=`cat /etc/system-release | awk '{ match($0, /([0-9]*)\.([0-9]*)\.([0-9]*)/, m); print m[1] "."  m[2] }'`
    fi
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

TARGET_DIR="${TARGET_DIR:-/opt/logpresso-sentry}"

USER_ID="$(id -nu)"
if [ "$USER_ID" != "root" ]; then
    echo "Only root can install logpresso"
    exit 1
fi

if [ -z "$GUID" ]; then GUID="$1"; fi
if [ -z "$TOKEN" ]; then TOKEN="$2"; fi
if [ -z "$URL" ]; then URL="$3"; fi

if [ -z "$GUID" ] || [ -z "$TOKEN" ] || [ -z "$URL" ]; then
    PRINT_USAGE=1
fi

if [ -n "$PRINT_USAGE" ]; then
    echo "Usage: ./install.sh [sentry guid] [auth token] [deploy url]"
    exit
fi

detect_os_version

ARCH="$(uname -m)"
JRE_URL="$URL/deploy/jre?os_name=$OS_NAME&os_ver=$OS_VER&arch=$ARCH"
PKG_URL="$URL/deploy/package?guid=$GUID&token=$TOKEN&pkg=sentry-linux"

LP_USER="logpresso"
LP_GROUP="logpresso"

# Check if TARGET_DIR exists and is not empty
if [[ -d "$TARGET_DIR" && -n "$(ls -A "$TARGET_DIR")" ]]; then
    echo "$TARGET_DIR exists and is not empty. Aborted."
    exit 1
fi

# Set SYSTEM_UNIT_DIR to a default value if not already set
SYSTEM_UNIT_DIR="${SYSTEM_UNIT_DIR:-/usr/lib/systemd/system}"

# Check if the directory exists
if [ ! -e "$SYSTEM_UNIT_DIR" ]; then
    echo "Cannot find the systemd unit directory at $SYSTEM_UNIT_DIR."
    echo "Use 'export SYSTEM_UNIT_DIR=SOME_PATH' to set the correct path, then retry running install.sh."
    exit 1
fi

# List of commands to check
commands=("ifconfig" "netstat" "unzip" "wget" "tar" "gunzip")

# Loop through each command and check if it's executable
for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "'$cmd' is not installed or not in the PATH."
        echo "Try run following."
		echo "    dnf install -y -q unzip wget tar net-tools && ./install.sh"
        exit 1
    fi
done

echo "Pre-checking for Logpresso Sentry Installation succeeded."

# Define a function for error handling
error_handling() {
    echo "An error occurred. Starting rollback..."

    rm -rf $TARGET_DIR

    echo "Rollback completed."

    # Exit with the original error status
    exit $?
}

# Set up the trap to call error_handling function on any error
trap 'error_handling' ERR

# Set the script to exit on error
set -e

echo "Creating $TARGET_DIR, user \"$LP_USER\" and group \"$LP_GROUP\"..."

if [ -z "$(getent passwd "$LP_USER")" ]; then
    useradd -s /sbin/nologin -d "$TARGET_DIR" "$LP_USER" 2>/dev/null
fi

# Create the target directory
mkdir -p "$TARGET_DIR"

# Grant permissions to the logpresso user
chown logpresso:logpresso "$TARGET_DIR"

if ! sudo -u logpresso test -r "$TARGET_DIR" || \
   ! sudo -u logpresso test -w "$TARGET_DIR" || \
   ! sudo -u logpresso test -x "$TARGET_DIR"; then
    echo "The logpresso user does not have adequate permissions on $TARGET_DIR."
    exit 1
fi

cd $TARGET_DIR

echo -n "Downloading Java Runtime Environment..."
wget --no-check-certificate -q -O "$TARGET_DIR"/jre.gz "$JRE_URL" || rm "$TARGET_DIR"/jre.gz

if [ -f "$TARGET_DIR"/jre.gz ]; then
  echo "done"
else
  echo "error"
  echo " - CHeck if $OS_NAME $OS_VER $ARCH supports JRE 6 or later"
  echo " - Check if required JRE have been uploaded to deployment server"
  exit 1
fi

echo -n "Downloading Logpresso Linux Sentry..."
wget --no-check-certificate -q -O "$TARGET_DIR"/sentry.zip "$PKG_URL" || rm "$TARGET_DIR"/sentry.zip

if [ -f "$TARGET_DIR/sentry.zip" ]; then
  echo "done"
else
  rm "$TARGET_DIR"/jre.gz
  echo "error"
  echo " - Check if sentry guid '$GUID' is registered"
  echo " - Check if auth token '$TOKEN' is correct"
  echo " - Check if linux sentry package have been uploaded to deployment server"
  exit 1
fi

echo -n "Extracting Java Runtime Environment..."
mkdir "$TARGET_DIR"/jre
tar xzpf "$TARGET_DIR"/jre.gz -C "$TARGET_DIR"/jre
rm "$TARGET_DIR"/jre.gz

JRE_DIR=$(ls "$TARGET_DIR"/jre/)
mv "$TARGET_DIR"/jre/"$JRE_DIR"/* "$TARGET_DIR"/jre/
rmdir "$TARGET_DIR"/jre/"$JRE_DIR"
echo "done"

echo -n "Extracting Logpresso Linux Sentry..."
unzip -q -o "$TARGET_DIR"/sentry.zip -d "$TARGET_DIR"
rm "$TARGET_DIR"/sentry.zip
echo "done"

echo "Installing Logpresso Sentry..."
# for pid logging
mkdir /var/run/logpresso || true # ignore already existing directory
chown $LP_USER:$LP_GROUP /var/run/logpresso
chown $LP_USER:$LP_GROUP "$TARGET_DIR" -R

export JAVA_HOME="$TARGET_DIR/jre"
if [ -f $SCRIPT_DIR/logpresso.conf ]; then
	mkdir -p "$TARGET_DIR"/etc
	cp $SCRIPT_DIR/logpresso.conf "$TARGET_DIR"/etc/logpresso.conf
else 
	"$TARGET_DIR"/logpresso install config -m sentry
fi
"$TARGET_DIR"/logpresso install sentry -g "$GUID" -t "$TOKEN" -a "$URL" -b "$BASE" -p "$RPC_PORT"
echo "done"

