#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}Warning: This will stop and remove ALL containers, images, volumes, and networks.${NC}"
read -p "Are you sure you want to proceed? (y/n): " confirm

if [[ $confirm != "y" ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo -e "\n${GREEN}1. Stopping and removing Docker Compose services (including volumes)...${NC}"

docker compose down -v --remove-orphans 2>/dev/null || echo "No active compose project found."

echo -e "\n${GREEN}2. Stopping all running containers...${NC}"
docker stop $(docker ps -aq) 2>/dev/null

echo -e "\n${GREEN}3. Removing all containers, networks, and images...${NC}"

docker system prune -a --volumes -f

echo -e "\n${GREEN}4. Purging BuildKit cache...${NC}"
docker builder prune -a -f

echo -e "\n${GREEN}5. Final check for dangling volumes...${NC}"
docker volume prune -f

echo -e "\n${RED}Cleanup Complete.${NC}"
docker ps -a
docker images
docker volume ls
