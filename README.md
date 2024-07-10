# Docker Management Tool

## Overview

This shell script provides a comprehensive solution for managing Docker installations, networks, and container configurations across various Linux distributions. It offers a user-friendly dialog-based interface for tasks such as installing Docker, setting up networks, and creating docker-compose files for popular applications.

## Features

1. Docker CE and Docker Compose installation and removal
2. Docker network creation and management
3. Automated docker-compose.yml generation for selected applications
4. Multi-distribution compatibility
5. Dialog-based user interface

## Supported Operating Systems

- CentOS
- Debian
- Ubuntu
- Arch Linux
- OpenSUSE
- ARM64 / Raspbian

## Supported Applications

1. AdGuard Home
2. BunkerWeb
3. Grafana
4. Home Assistant
5. Netmaker
6. Nextcloud
7. Nginx Proxy Manager
8. Plex Media Server
9. Portainer-CE
10. Tailscale
11. Uptime Kuma
12. Vaultwarden

## Usage

1. Save the script as `docker_manager.sh`
2. Make it executable:
   ```
   chmod +x docker_manager.sh
   ```
3. Run the script with root privileges:
   ```
   sudo ./docker_manager.sh
   ```

## Main Menu Options

1. Install Docker
2. Remove Docker
3. Set up Docker network
4. Remove Docker network
5. Create docker-compose.yml
6. Exit

## Creating a docker-compose.yml

1. Select option 5 from the main menu
2. Choose the desired application from the list
3. The script will generate a basic docker-compose.yml file for the selected application

## Notes

- Internet connectivity is required for Docker installation and docker-compose.yml file creation
- Generated docker-compose.yml files are basic templates and may need further customization
- The script requires root privileges to run
- The `dialog` package must be installed for the menu interface to work

## Customization

Users can modify the script to add more applications or customize the docker-compose.yml templates as needed.

## Troubleshooting

If you encounter any issues:
1. Ensure you're running the script with root privileges
2. Check your internet connection
3. Verify that your operating system is supported
4. Make sure the `dialog` package is installed

## Disclaimer

This script is provided as-is, without any warranties. Users should review and understand the script before running it on their systems. Always backup important data before making system changes.
