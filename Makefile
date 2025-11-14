# Inception - Docker Infrastructure Setup
# Login: elbaraka

COMPOSE_FILE = ./srcs/docker-compose.yml
DATA_PATH = /home/elbaraka/data
WORDPRESS_PATH = $(DATA_PATH)/wordpress
DB_PATH = $(DATA_PATH)/mariadb

all: setup build up

setup:
	@echo "Creating data directories..."
	@mkdir -p $(WORDPRESS_PATH)
	@mkdir -p $(DB_PATH)
	@echo "Data directories created successfully!"

build:
	@echo "Building Docker images..."
	@docker-compose -f $(COMPOSE_FILE) build
	@echo "Build complete!"

up:
	@echo "Starting containers..."
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "Containers started successfully!"
	@echo "Access your site at: https://elbaraka.42.fr"

down:
	@echo "Stopping containers..."
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "Containers stopped!"

stop:
	@echo "Stopping containers..."
	@docker-compose -f $(COMPOSE_FILE) stop
	@echo "Containers stopped!"

start:
	@echo "Starting containers..."
	@docker-compose -f $(COMPOSE_FILE) start
	@echo "Containers started!"

clean: down
	@echo "Cleaning up containers and images..."
	@docker system prune -af
	@echo "Cleanup complete!"

fclean: clean
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_PATH)
	@echo "Full cleanup complete!"

re: fclean all

logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

ps:
	@docker-compose -f $(COMPOSE_FILE) ps

.PHONY: all setup build up down stop start clean fclean re logs ps