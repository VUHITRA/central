docker-compose-dev := docker compose --profile central -f docker-compose.yml -f docker-compose.dev.yml
docker-compose-main := docker compose -f docker-compose.yml
docker-compose-older := docker compose -f docker-compose.older.yml

.PHONY: dev
dev:
	$(docker-compose-dev) up -d

.PHONY: stop
stop:
	$(docker-compose-dev) stop

# Main compose stack commands
.PHONY: up
up:
	$(docker-compose-main) up -d

.PHONY: down
down:
	$(docker-compose-main) down

.PHONY: restart
restart:
	$(docker-compose-main) restart

.PHONY: stop-main
stop-main:
	$(docker-compose-main) stop

# Older compose stack commands
.PHONY: up-older
up-older:
	$(docker-compose-older) up -d

.PHONY: down-older
down-older:
	$(docker-compose-older) down

.PHONY: restart-older
restart-older:
	$(docker-compose-older) restart

.PHONY: stop-older
stop-older:
	$(docker-compose-older) stop

# Volume management
.PHONY: prune-volumes
prune-volumes:
	docker volume prune -f

.PHONY: prune-all
prune-all:
	docker system prune -a --volumes -f

.PHONY: prune-all-volumes
prune-all-volumes:
	docker volume prune -f
	docker volume rm -f central_postgres14 central_secrets central_enketo_redis_main central_enketo_redis_cache central_enketo_redis_main_older central_enketo_redis_cache_older central_transfer 2>/dev/null || true

# Backup and restore
.PHONY: restore-backup
restore-backup:
	@if [ -f .env ]; then \
		echo "Loading environment variables from .env file..."; \
		set -a && . ./.env && set +a; \
	fi; \
	if [ -z "$$BACKUP_FILE" ] || [ -z "$$SECRET_PASS" ]; then \
		echo "Error: BACKUP_FILE and SECRET_PASS are required"; \
		echo "Please create a .env file with:"; \
		echo "  BACKUP_FILE=/path/to/backup.zip"; \
		echo "  SECRET_PASS=your_secret_password"; \
		echo "Or export these variables directly"; \
		exit 1; \
	fi; \
	$(docker-compose-main) exec service node /usr/odk/lib/bin/restore.js "$$BACKUP_FILE" "$$SECRET_PASS"

# Database management
.PHONY: db-migrate
db-migrate:
	$(docker-compose-main) exec service node lib/bin/run-migrations.js

.PHONY: db-migrate-older
db-migrate-older:
	$(docker-compose-older) exec service node lib/bin/run-migrations.js

.PHONY: db-reset
db-reset:
	@echo "Warning: This will reset the database and lose all data!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	$(docker-compose-main) down
	docker volume rm -f central_postgres14 2>/dev/null || true
	$(docker-compose-main) up -d

.PHONY: db-reset-older
db-reset-older:
	@echo "Warning: This will reset the older database and lose all data!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	$(docker-compose-older) down
	docker volume rm -f central_postgres14 2>/dev/null || true
	$(docker-compose-older) up -d

# Utility commands
.PHONY: logs
logs:
	$(docker-compose-main) logs -f

.PHONY: logs-older
logs-older:
	$(docker-compose-older) logs -f

.PHONY: ps
ps:
	$(docker-compose-main) ps

.PHONY: ps-older
ps-older:
	$(docker-compose-older) ps

.PHONY: help
help:
	@echo "Available commands:"
	@echo "  dev            - Start development environment"
	@echo "  up             - Start main compose stack"
	@echo "  down           - Stop and remove main compose stack"
	@echo "  restart        - Restart main compose stack"
	@echo "  stop-main      - Stop main compose stack"
	@echo "  up-older       - Start older compose stack"
	@echo "  down-older     - Stop and remove older compose stack"
	@echo "  restart-older  - Restart older compose stack"
	@echo "  stop-older     - Stop older compose stack"
	@echo "  prune-volumes  - Remove unused Docker volumes"
	@echo "  prune-all      - Remove all unused Docker resources"
	@echo "  prune-all-volumes - Remove all volumes (anonymous and named)"
	@echo "  db-migrate     - Run database migrations for main stack"
	@echo "  db-migrate-older - Run database migrations for older stack"
	@echo "  db-reset       - Reset database (WARNING: loses all data)"
	@echo "  db-reset-older - Reset older database (WARNING: loses all data)"
	@echo "  restore-backup - Restore ODK Central backup"
	@echo "  logs           - Show logs for main stack"
	@echo "  logs-older     - Show logs for older stack"
	@echo "  ps             - Show running containers (main)"
	@echo "  ps-older       - Show running containers (older)"
	@echo "  help           - Show this help message"
