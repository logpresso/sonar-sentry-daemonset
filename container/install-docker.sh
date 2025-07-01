# Try to generate GUID based on hostname
if [ -n "$K8S_NODE_NAME" ]; then
    if [[ "$K8S_NODE_NAME" =~ \.compute\.internal$ ]]; then
        SHORT_HOST_NAME="${K8S_NODE_NAME%.compute.internal}"
    else
        SHORT_HOST_NAME="${K8S_NODE_NAME%.*}"
    fi
else
    if command -v hostname &> /dev/null; then
        SHORT_HOST_NAME=$(hostname)
    elif [ -f /proc/sys/kernel/hostname ]; then
        SHORT_HOST_NAME=$(cat /proc/sys/kernel/hostname)
    elif [ -f /etc/hostname ]; then
        SHORT_HOST_NAME=$(cat /etc/hostname)
    else
        echo "Error: Could not determine hostname"
        exit 1
    fi
    SHORT_HOST_NAME="${SHORT_HOST_NAME%%.*}"
fi

if [ -n "$RELEASE_NAME" ]; then
    if [ "$DEPLOYMENT_TYPE" == "DaemonSet" ]; then
        GUID=$RELEASE_NAME-ss-ds-$SHORT_HOST_NAME
    elif [ "$DEPLOYMENT_TYPE" == "Deployment" ]; then
        GUID=$RELEASE_NAME-ss-dp
    else
        GUID=$RELEASE_NAME-ss-unknown
    fi
else 
    GUID=$SHORT_HOST_NAME
fi

TOKEN=${SENTRY_AUTH_TOKEN}
URL=$DEPLOY_URL
BASE=$BASE_ADDR
RPC_PORT=7140
CONF_FILE=logpresso.conf

if [ -n "$TOKEN" ]; then
    echo "Public IP: `curl -s ifconfig.me`"
	#SONAR_API_KEY=${SONAR_API_KEY:-`cat /etc/secrets/sonar-api-key`}
	echo "Registering Logpresso Sentry..."
	API_TARGET=${DEPLOY_URL/:44300/:$DEPLOY_API_PORT}/api/sonar/sentries
	echo GUID: $GUID
	echo API_TARGET: $API_TARGET
	RESPONSE=$(curl -s -k -X POST "$API_TARGET" \
		-d "sentry_guid=${GUID}&auth_token=${TOKEN}&os=linux&base=$BASE" \
		-H "Authorization: Bearer ${SONAR_API_KEY}")
    if [ $? -eq 0 ]; then
        echo "Logpresso Sentry registered successfully."
    else
        echo "Failed to register Logpresso Sentry."
        echo "Response: $RESPONSE"
        exit 1
    fi
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

if [ -z "$TOKEN" ]; then TOKEN="$2"; fi
if [ -z "$URL" ]; then URL="$3"; fi

if [ -z "$TOKEN" ] || [ -z "$URL" ]; then
    echo GUID: [$GUID]
    echo TOKEN: [$TOKEN]
    echo URL: [$URL]
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
    ORIG_ERROR=$?
    echo "An error occurred. Starting rollback..."

    rm -rf $TARGET_DIR

    echo "Rollback completed."

    if [ -n "$current_trap" ]; then
        eval "$current_trap"
    fi

    # Exit with the original error status
    exit $ORIG_ERROR
}

# Set up the trap to call error_handling function on any error
current_trap=$(trap -p ERR)
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

echo "Downloading Java Runtime Environment..."
echo URL: $JRE_URL
wget --no-check-certificate -q -O "$TARGET_DIR"/jre.gz "$JRE_URL" || rm "$TARGET_DIR"/jre.gz

if [ -f "$TARGET_DIR"/jre.gz ]; then
  echo "done"
else
  echo "error"
  echo " - CHeck if $OS_NAME $OS_VER $ARCH supports JRE 6 or later"
  echo " - Check if required JRE have been uploaded to deployment server"
  exit 1
fi

set +e 
echo "Downloading Logpresso Linux Sentry..."
wget --no-check-certificate -q -O "$TARGET_DIR"/sentry.zip "$PKG_URL" || rm "$TARGET_DIR"/sentry.zip
if [ ! -f "$TARGET_DIR/sentry.zip" ]; then
    echo "retrying once more..."
    set -e
    # retry once for ALB
    wget --no-check-certificate -q -O "$TARGET_DIR"/sentry.zip "$PKG_URL" || rm "$TARGET_DIR"/sentry.zip
fi
set -e


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

echo "Extracting Java Runtime Environment..."
mkdir "$TARGET_DIR"/jre
tar xzpf "$TARGET_DIR"/jre.gz -C "$TARGET_DIR"/jre
rm "$TARGET_DIR"/jre.gz

JRE_DIR=$(ls "$TARGET_DIR"/jre/)
mv "$TARGET_DIR"/jre/"$JRE_DIR"/* "$TARGET_DIR"/jre/
rmdir "$TARGET_DIR"/jre/"$JRE_DIR"
echo "done"

echo "Extracting Logpresso Linux Sentry..."
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
    sed -i "s|^BASEDIR=.*|BASEDIR=\"$TARGET_DIR\"|" "$TARGET_DIR"/etc/logpresso.conf
else 
	"$TARGET_DIR"/logpresso install config -m sentry
fi

set +e
trap - ERR
"$TARGET_DIR"/logpresso install sentry -g "$GUID" -t "$TOKEN" -a "$URL" -b "$BASE" -p "$RPC_PORT"
SENTRY_INSTALL_ERROR=$?
if [ ! "$SENTRY_INSTALL_ERROR" == "0" ]; then
    echo "retrying once more..."
    set -e
    trap 'error_handling' ERR
    # retry once for ALB
    "$TARGET_DIR"/logpresso install sentry -g "$GUID" -t "$TOKEN" -a "$URL" -b "$BASE" -p "$RPC_PORT"
fi
set -e

# Check if systemctl is available and working
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    echo "Systemctl is available and working. Installing systemd service..."
    
    SVCFILE="$SYSTEM_UNIT_DIR/logpresso-sentry.service"
    ETCDIR="$TARGET_DIR/etc"

    echo -n "Installing $SVCFILE... "
    cat > "$SVCFILE" <<-EOF
[Unit]
Description=Logpresso Sentry
After=multi-user.target network.target
ConditionPathExists=$ETCDIR/logpresso.conf
Documentation=https://ko.logpresso.com/documents

[Service]
User=$LP_USER
Group=$LP_GROUP
Type=forking
PIDFile=$TARGET_DIR/cache/run.pid
Environment=PKGDIR=$TARGET_DIR
ExecStart=/bin/sh $TARGET_DIR/logpresso start
ExecStop=/bin/sh $TARGET_DIR/logpresso stop
TimeoutStopSec=1200
LimitNOFILE=65535
Restart=on-failure
RuntimeDirectory=logpresso

[Install]
WantedBy=multi-user.target
EOF
    echo "done"

    echo "Starting daemon..."
    systemctl enable logpresso-sentry
    systemctl start logpresso-sentry
    echo "done"
else
    echo "Systemctl is not available or not working. Skipping systemd service installation."
    echo "You may need to start the service manually using: $TARGET_DIR/logpresso start"
    echo "done"
fi

if [ -n "$current_trap" ]; then
    eval "$current_trap"
fi
