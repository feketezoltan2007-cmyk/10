########################################
###              TELEPÍTÉS            ###
########################################
if [[ "$MODE" == "1" ]]; then

NODE_STATUS=$(is_installed node-red)
LAMP_STATUS=$(is_installed lamp)
MQTT_STATUS=$(is_installed mqtt)
MC_STATUS=$(is_installed mc)

INSTALL_NODE_RED=0
INSTALL_LAMP=0
INSTALL_MQTT=0
INSTALL_MC=0

echo -e "\e[36mMit szeretnél telepíteni? \e[0m"
echo -e "  \e[32m1\e[0m - MINDENT telepít"
echo -e "  \e[33m2\e[0m - Node-RED            – $NODE_STATUS"
echo -e "  \e[94m3\e[0m - Apache+MariaDB+PHP – $LAMP_STATUS"
echo -e "  \e[35m4\e[0m - MQTT (Mosquitto)   – $MQTT_STATUS"
echo -e "  \e[36m5\e[0m - mc                  – $MC_STATUS"

read -rp $'\e[37mVálasztás: \e[0m' CHOICES </dev/tty || CHOICES=""

if echo "$CHOICES" | grep -qw "1"; then
  INSTALL_NODE_RED=1
  INSTALL_LAMP=1
  INSTALL_MQTT=1
  INSTALL_MC=1
fi

for c in $CHOICES; do
  case "$c" in
    2) INSTALL_NODE_RED=1 ;;
    3) INSTALL_LAMP=1 ;;
    4) INSTALL_MQTT=1 ;;
    5) INSTALL_MC=1 ;;
  esac
done

apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget unzip ca-certificates gnupg lsb-release

[[ $INSTALL_NODE_RED -eq 1 ]] && npm install -g --unsafe-perm node-red || true
[[ $INSTALL_LAMP -eq 1 ]] && apt-get install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl
[[ $INSTALL_MQTT -eq 1 ]] && apt-get install -y mosquitto mosquitto-clients
[[ $INSTALL_MC -eq 1 ]] && apt-get install -y mc

# LAMP telepítés után: felhasználó létrehozása és adatbázis
if [[ $INSTALL_LAMP -eq 1 ]]; then
    # Rendszerfelhasználó létrehozása
    if ! id -u user >/dev/null 2>&1; then
        useradd -m -s /bin/bash user
        echo "user:user123" | chpasswd
        echo "Felhasználó 'user' létrehozva jelszó: user123"
    fi

    # MariaDB adatbázis létrehozása
    DB_NAME="node-red"
    DB_USER="user"
    DB_PASS="user123"

    mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
    mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    echo "Adatbázis '$DB_NAME' létrehozva a felhasználóval '$DB_USER'."
fi

{
  echo "----------------------------------------"
  echo "IDŐPONT: $START_TIME"
  echo "MŰVELET: TELEPÍTÉS"
  echo "Node-RED: $INSTALL_NODE_RED"
  echo "LAMP:     $INSTALL_LAMP"
  echo "MQTT:     $INSTALL_MQTT"
  echo "MC:       $INSTALL_MC"
  echo "ÁLLAPOT:  SIKERES"
} >> "$LOGFILE"

echo -e "\e[32mTelepítés kész!\e[0m"
exit 0
fi
