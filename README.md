# Inception

Containerized WordPress + MariaDB stack built from the ground up with custom Debian-based images, TLS termination, and persistent bind-mounted volumes.

## Stack overview

| Service   | Image Source                 | Purpose |
|-----------|-----------------------------|---------|
| `nginx`   | `srcs/requirements/nginx`    | Terminates TLS on port 443, proxies PHP traffic to WordPress, and auto-generates a self-signed cert if one is missing. |
| `wordpress` | `srcs/requirements/wordpress` | Runs PHP-FPM 7.4, bootstraps WordPress via WP-CLI, and provisions an admin plus an editor account. |
| `mariadb` | `srcs/requirements/mariadb`  | Initializes the database, root password, and dedicated WordPress user before running `mysqld`. |

All containers share a custom Docker network (`inception`) and use bind-mounted volumes so that database tables and WordPress uploads survive lifecycle operations.

## Repository layout

```
Makefile                # Helper targets that wrap docker compose
srcs/
├─ docker-compose.yml   # Defines the 3 services, volumes, and network
└─ requirements/
   ├─ nginx/            # TLS config, default vhost, entrypoint
   ├─ wordpress/        # PHP-FPM config + WP bootstrap logic
   └─ mariadb/          # MariaDB config + initialization script
```

## Prerequisites

- Docker Engine 24+ and Docker Compose V2
- GNU Make (optional but recommended for the provided targets)
- WSL2/Linux host paths available for the bind mounts referenced in `docker-compose.yml`

## 1. Prepare persistent directories

The compose file binds the volumes to `/home/elbaraka/data/...`. Update those paths if needed, or create matching directories in your WSL distribution:

```bash
mkdir -p /home/elbaraka/data/mariadb
mkdir -p /home/elbaraka/data/wordpress
```

If you prefer a different location (e.g., `/home/$USER/data`), edit the `device` entry under each volume in `srcs/docker-compose.yml`.

## 2. Create the `.env` file

The services read secrets and metadata from `srcs/.env`. Copy the template below, adjust the values, and keep the file private (never commit it).

```bash
# Database
MYSQL_ROOT_PASSWORD=super_secure_root_pass
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_user_pass

# WordPress runtime
DB_HOST=mariadb:3306
WP_URL=https://elbaraka.42.fr
WP_TITLE=Inception Blog
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=change_me_admin
WP_ADMIN_EMAIL=admin@example.com
WP_USER=editor
WP_USER_PASSWORD=change_me_editor
WP_USER_EMAIL=editor@example.com
```

Need a different domain? Update `WP_URL` here **and** the `server_name` plus certificate subject found in `srcs/requirements/nginx/conf/default.conf` and `tools/docker-entrypoint.sh`.

## 3. Build and run the stack

From the repository root:

```bash
make all        # build images and start every service in detached mode
```

Once the containers are up, browse to `https://elbaraka.42.fr` (or the domain you configured). Because the certificate is self-signed, expect a browser warning unless you import `nginx.crt` into your trust store.

### Lifecycle helpers

```bash
make stop       # pause the containers without removing volumes
make start      # resume after a stop
make down       # remove containers while keeping bind-mounted data
```

To inspect logs, use Docker directly, e.g. `docker compose -f srcs/docker-compose.yml logs -f wordpress`.

## Maintenance tips

- The MariaDB entrypoint is idempotent; it only seeds credentials the first time it runs against an empty data directory. Delete the contents of `/home/elbaraka/data/mariadb` if you need a fresh database.
- The WordPress entrypoint skips installation when `wp-config.php` already exists. To force a reinstall, remove the files under `/home/elbaraka/data/wordpress` and restart the stack.
- To regenerate the self-signed certificate, delete `/etc/nginx/ssl/nginx.*` from inside the running container (`docker exec -it nginx bash`) or remove the container so the entrypoint can recreate the files on the next start.

## Troubleshooting

- **Database connection errors**: confirm the credentials in `.env` match the user created in MariaDB, and that `DB_HOST` stays `mariadb:3306` (service name + port inside the compose network).
- **Port 443 already in use**: stop the conflicting service (`sudo lsof -i :443`) or change the exposed port in `docker-compose.yml`.
- **File permission issues**: WordPress files must be writable by `www-data`. Run `sudo chown -R www-data:www-data /home/elbaraka/data/wordpress` from inside WSL if uploads fail.

## Next steps

- Point your `/etc/hosts` (or Windows hosts file) to map `elbaraka.42.fr` to `127.0.0.1` for local testing.
- Consider swapping the self-signed certificate for a trusted one once the stack runs on a public server (e.g., by mounting Let's Encrypt assets into the Nginx container).
