#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Function to detect the operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo "Unable to detect operating system"
        exit 1
    fi
}

# Function to install Docker-CE and Docker-Compose
install_docker() {
    case $OS in
        "CentOS Linux")
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io
            systemctl start docker
            systemctl enable docker
            ;;
        "Debian GNU/Linux"|"Ubuntu")
            apt-get update
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/$( echo "$OS" | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$( echo "$OS" | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
        "Arch Linux")
            pacman -Sy docker
            systemctl start docker
            systemctl enable docker
            ;;
        "openSUSE Leap"|"openSUSE Tumbleweed")
            zypper install -y docker
            systemctl start docker
            systemctl enable docker
            ;;
        "Raspbian GNU/Linux")
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac

    # Install Docker-Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

# Function to remove Docker-CE and Docker-Compose
remove_docker() {
    case $OS in
        "CentOS Linux")
            yum remove -y docker-ce docker-ce-cli containerd.io
            rm -rf /var/lib/docker
            ;;
        "Debian GNU/Linux"|"Ubuntu")
            apt-get purge -y docker-ce docker-ce-cli containerd.io
            apt-get autoremove -y
            rm -rf /var/lib/docker
            ;;
        "Arch Linux")
            pacman -R docker
            rm -rf /var/lib/docker
            ;;
        "openSUSE Leap"|"openSUSE Tumbleweed")
            zypper remove -y docker
            rm -rf /var/lib/docker
            ;;
        "Raspbian GNU/Linux")
            apt-get purge -y docker-ce docker-ce-cli containerd.io
            apt-get autoremove -y
            rm -rf /var/lib/docker
            ;;
        *)
            echo "Unsupported operating system"
            exit 1
            ;;
    esac

    # Remove Docker-Compose
    rm -f /usr/local/bin/docker-compose
}

# Function to set up Docker network
setup_network() {
    network_name=$(dialog --inputbox "Enter network name:" 8 40 "docker_network" 2>&1 >/dev/tty)
    subnet=$(dialog --inputbox "Enter subnet (e.g., 172.18.0.0/16):" 8 40 "172.18.0.0/16" 2>&1 >/dev/tty)
    
    docker network create --driver bridge --subnet $subnet $network_name
    dialog --msgbox "Docker network $network_name created with subnet $subnet" 8 40
}

# Function to remove Docker network
remove_network() {
    network_name=$(docker network ls --format "{{.Name}}" | dialog --menu "Select network to remove:" 20 60 10 2>&1 >/dev/tty)
    if [ -n "$network_name" ]; then
        docker network rm $network_name
        dialog --msgbox "Docker network $network_name removed" 8 40
    fi
}

# Function to create docker-compose.yml for selected application
create_docker_compose() {
    app=$1
    case $app in
        "AdGuard Home")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  adguardhome:
    image: adguard/adguardhome
    container_name: adguardhome
    ports:
      - 53:53/tcp
      - 53:53/udp
      - 80:80/tcp
      - 443:443/tcp
      - 3000:3000/tcp
    volumes:
      - ./workdir:/opt/adguardhome/work
      - ./confdir:/opt/adguardhome/conf
    restart: unless-stopped
EOL
            ;;
        "BunkerWeb")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  bunkerweb:
    image: bunkerity/bunkerweb:latest
    ports:
      - 80:8080
      - 443:8443
    volumes:
      - ./data:/data
    environment:
      - SERVER_NAME=example.com
    restart: unless-stopped
EOL
            ;;
        "Grafana")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  grafana:
    image: grafana/grafana
    container_name: grafana
    ports:
      - 3000:3000
    volumes:
      - grafana-storage:/var/lib/grafana
    restart: unless-stopped

volumes:
  grafana-storage:
EOL
            ;;
        "Home Assistant")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  homeassistant:
    container_name: homeassistant
    image: "ghcr.io/home-assistant/home-assistant:stable"
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    privileged: true
    network_mode: host
EOL
            ;;
        "Netmaker")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  netmaker:
    image: gravitl/netmaker:latest
    container_name: netmaker
    volumes:
      - ./config:/etc/netmaker
      - ./data:/root/data
    network_mode: host
    restart: always
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      SERVER_HOST: "example.com"
EOL
            ;;
        "Nextcloud")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  nextcloud:
    image: nextcloud
    container_name: nextcloud
    ports:
      - 8080:80
    volumes:
      - nextcloud:/var/www/html
    restart: unless-stopped

volumes:
  nextcloud:
EOL
            ;;
        "Nginx Proxy Manager")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  npm:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx-proxy-manager
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    restart: unless-stopped
EOL
            ;;
        "Plex Media Server")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  plex:
    image: plexinc/pms-docker
    container_name: plex
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=claim-XXXXXXXXXXXXXXXXXX
    volumes:
      - ./config:/config
      - ./transcode:/transcode
      - /path/to/media:/data
    restart: unless-stopped
EOL
            ;;
        "Portainer-CE")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - 8000:8000
      - 9000:9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped

volumes:
  portainer_data:
EOL
            ;;
        "Tailscale")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  tailscale:
    image: tailscale/tailscale
    container_name: tailscale
    volumes:
      - ./var-lib:/var/lib
      - /dev/net/tun:/dev/net/tun
    network_mode: host
    privileged: true
    restart: unless-stopped
EOL
            ;;
        "Uptime Kuma")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    volumes:
      - ./data:/app/data
    ports:
      - 3001:3001
    restart: always
EOL
            ;;
        "Vaultwarden")
            cat > docker-compose.yml <<EOL
version: '3'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    ports:
      - 80:80
    volumes:
      - ./vw-data:/data
    restart: unless-stopped
EOL
            ;;
        *)
            dialog --msgbox "Invalid application selection" 8 40
            return
            ;;
    esac
    dialog --msgbox "docker-compose.yml created for $app" 8 40
}

# Main menu function
main_menu() {
    while true; do
        choice=$(dialog --clear --backtitle "Docker Management by MATORI NET" \
            --title "Main Menu" \
            --menu "Choose an option:" 15 60 8 \
            1 "Install Docker" \
            2 "Remove Docker" \
            3 "Set up Docker network" \
            4 "Remove Docker network" \
            5 "Create docker-compose.yml" \
            6 "Exit" \
            2>&1 >/dev/tty)

        case $choice in
            1)
                dialog --infobox "Installing Docker..." 5 30
                install_docker
                dialog --msgbox "Docker installed successfully" 5 30
                ;;
            2)
                dialog --infobox "Removing Docker..." 5 30
                remove_docker
                dialog --msgbox "Docker removed successfully" 5 30
                ;;
            3)
                setup_network
                ;;
            4)
                remove_network
                ;;
            5)
                app=$(dialog --clear --backtitle "Docker Management" \
                    --title "Create docker-compose.yml" \
                    --menu "Choose an application:" 20 60 12 \
                    1 "AdGuard Home" \
                    2 "BunkerWeb" \
                    3 "Grafana" \
                    4 "Home Assistant" \
                    5 "Netmaker" \
                    6 "Nextcloud" \
                    7 "Nginx Proxy Manager" \
                    8 "Plex Media Server" \
                    9 "Portainer-CE" \
                    10 "Tailscale" \
                    11 "Uptime Kuma" \
                    12 "Vaultwarden" \
                    2>&1 >/dev/tty)
                
                case $app in
                    1) create_docker_compose "AdGuard Home" ;;
                    2) create_docker_compose "BunkerWeb" ;;
                    3) create_docker_compose "Grafana" ;;
                    4) create_docker_compose "Home Assistant" ;;
                    5) create_docker_compose "Netmaker" ;;
                    6) create_docker_compose "Nextcloud" ;;
                    7) create_docker_compose "Nginx Proxy Manager" ;;
                    8) create_docker_compose "Plex Media Server" ;;
                    9) create_docker_compose "Portainer-CE" ;;
                    10) create_docker_compose "Tailscale" ;;
                    11) create_docker_compose "Uptime Kuma" ;;
                    12) create_docker_compose "Vaultwarden" ;;
                    *) ;;
                esac
                ;;
            6)
                clear
                exit 0
                ;;
            *)
                dialog --msgbox "Invalid option" 5 20
                ;;
        esac
    done
}

# Main script execution
check_root
detect_os
main_menu
