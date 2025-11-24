# Inception

Inception is a systems-administration and DevOps project that guides you through building a **mini self-contained infrastructure with Docker**.  
You learn how to design, build, and orchestrate multiple services (web server, database, WordPress, etc.) using **Docker**, **Docker Compose**, and **shell scripts**, without relying on pre-built “all-in-one” images.

This README is a step‑by‑step guide to understand, set up, run, and extend the project.

---

## 1. Project Overview

### 1.1. Goal

- Build a **multi‑container** environment using Docker.
- Each service runs in its **own container**.
- No container should use an image like `wordpress`, `mariadb`, etc. directly:  
  you **build your own images with Dockerfiles**.
- Store data in **named volumes** so it persists across container restarts.
- Use **Docker Compose** to orchestrate the setup.

Typical services you will have (names may vary slightly per subject/version):

- **Nginx** (reverse proxy, HTTPS/TLS termination)
- **WordPress + PHP-FPM**
- **MariaDB** (or MySQL-compatible DB)
- Optional extras depending on your version of the project:
  - Redis cache
  - FTP / Adminer / other utilities

> The idea is to simulate a small but realistic production‑like environment.

---

## 2. Repository Structure

> Exact paths may differ slightly from your repo, but this is the usual structure for Inception.

```text
.
├── Makefile
├── docker-compose.yml
├── srcs/
│   ├── requirements/
│   │   ├── mariadb/
│   │   │   ├── Dockerfile
│   │   │   └── tools/        # entrypoint scripts, config scripts
│   │   ├── nginx/
│   │   │   ├── Dockerfile
│   │   │   └── conf/         # nginx.conf, site config
│   │   └── wordpress/
│   │       ├── Dockerfile
│   │       └── tools/        # wp-cli, install script, init script
│   └── .env                  # environment variables (DB, domain, etc.)
└── ... (other scripts / configs)
```

- **Shell (58%)** – All the initialization, entrypoint, and helper scripts.
- **Dockerfile (35.7%)** – Custom images for each service.
- **Makefile (6.1%)** – High-level commands to build, run, stop, and clean the whole stack.

---

## 3. Prerequisites

Before you start:

1. **OS**: Linux or macOS is recommended.  
2. **Docker** installed and running:
   - Check: `docker --version`
3. **Docker Compose** (v2 or integrated with Docker):
   - Check: `docker compose version`
4. **Make**:
   - Check: `make --version`
5. Basic knowledge of:
   - Shell scripting
   - Docker and Dockerfiles
   - Networking basics (ports, localhost, etc.)

---

## 4. Configuration

### 4.1. Environment File (`.env`)

Most Inception setups use an `.env` file (often in `srcs/.env`) to configure:

- Domain and hostnames
- Database credentials
- WordPress admin credentials
- Volume paths

Typical variables might include:

```dotenv
# Domain
DOMAIN_NAME=yourlogin.42.fr

# Database
MYSQL_ROOT_PASSWORD=some_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password

# WordPress admin
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com
```

> **Important**:  
> - Do **not** commit real passwords. For a public repo, use examples or placeholders.  
> - Ensure `.env` is in `.gitignore` if it contains real secrets.

### 4.2. Volumes and Data Directories

Depending on your `docker-compose.yml`, volumes might be created under something like:

- `/home/<user>/data/wordpress`
- `/home/<user>/data/mariadb`

or defined as **named volumes**:

```yaml
volumes:
  wordpress_data:
  mariadb_data:
```

These ensure your **database** and **WordPress files** persist if the containers are recreated.

---

## 5. Understanding Each Service

### 5.1. MariaDB Service

- **Image**: Built from `srcs/requirements/mariadb/Dockerfile`.
- **Role**: Stores WordPress data (posts, users, options, etc.).
- **Init script**:
  - Creates the database defined in `.env`.
  - Creates the user and sets permissions.

Key ideas:

- The database container usually exposes port `3306` **only inside the Docker network**, not to the host.
- Initialization is often done by shell scripts executed as `ENTRYPOINT` or `CMD`.

### 5.2. WordPress + PHP-FPM Service

- **Image**: Built from `srcs/requirements/wordpress/Dockerfile`.
- **Role**: Runs the WordPress application with PHP-FPM.

Typical initialization steps:

1. Download WordPress core (via `wp-cli` or `curl`/`tar`).
2. Generate the `wp-config.php` file using `.env` DB variables.
3. Run the initial installation:
   - Site title
   - Admin user/password/mail
4. Start `php-fpm`.

WordPress listens on an internal port (e.g., `9000`) and is reached only by **Nginx** inside the Docker network.

### 5.3. Nginx Service

- **Image**: Built from `srcs/requirements/nginx/Dockerfile`.
- **Role**:
  - Acts as a **reverse proxy**.
  - Terminates **HTTPS** (serves TLS certificates).
  - Forwards PHP requests to the WordPress/PHP-FPM service.

Key config elements:

- Virtual host configuration (e.g., `/etc/nginx/conf.d/default.conf` or `/etc/nginx/sites-enabled/`).
- SSL certificates (self-signed or generated in Docker build/runtime).
- Forwarding to PHP-FPM, for example:

```nginx
location ~ \.php$ {
    fastcgi_pass  wordpress:9000;
    fastcgi_index index.php;
    include       fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

---

## 6. Orchestration with Docker Compose

The `docker-compose.yml` brings everything together:

- Defines services (`nginx`, `wordpress`, `mariadb`, possibly others).
- Connects them with a **Docker network**.
- Attaches **volumes**.
- Maps ports (e.g. host `443` → container `443` for HTTPS).

A simplified conceptual example:

```yaml
version: "3.8"

services:
  mariadb:
    build: ./srcs/requirements/mariadb
    env_file: ./srcs/.env
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - inception

  wordpress:
    build: ./srcs/requirements/wordpress
    depends_on:
      - mariadb
    env_file: ./srcs/.env
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception

  nginx:
    build: ./srcs/requirements/nginx
    depends_on:
      - wordpress
    volumes:
      - wordpress_data:/var/www/html:ro
    ports:
      - "443:443"
    networks:
      - inception

volumes:
  mariadb_data:
  wordpress_data:

networks:
  inception:
```

---

## 7. Makefile: Project Commands

The `Makefile` acts as a **shortcut** for all common Docker Compose operations.

Common targets (names may vary; adapt to your actual file):

```makefile
up:
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

clean:
	docker compose -f srcs/docker-compose.yml down -v
	docker system prune -f

re:
	make clean
	make up
```

Typical usage:

- `make` or `make up` – Build and start everything.
- `make down` – Stop containers.
- `make clean` – Remove containers and volumes (data wiped).
- `make re` – Clean and rebuild everything.

> Look in your `Makefile` to confirm the exact names and behavior.

---

## 8. Step‑by‑Step: From Zero to Running

### Step 1 – Clone the Repository

```bash
git clone git@github.com:barakamehdi/inception.git
cd inception
```

### Step 2 – Prepare Environment and Folders

1. Create your data folders if the project expects host directories, e.g.:

   ```bash
   mkdir -p /home/$USER/data/wordpress
   mkdir -p /home/$USER/data/mariadb
   ```

2. Create and fill in `srcs/.env`:

   ```bash
   cp srcs/.env.example srcs/.env   # if an example file exists
   nano srcs/.env                   # or your editor of choice
   ```

   Adjust:

   - `DOMAIN_NAME`
   - Database credentials
   - WordPress admin data

### Step 3 – Build and Run the Stack

Using the Makefile:

```bash
make
# or
make up
```

This will:

- Build the custom images from their Dockerfiles.
- Create and start all containers.
- Create volumes if not already existing.
- Run initialization scripts (DB, WordPress, etc.).

You can follow logs with:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

### Step 4 – Access the Site

1. Add an entry in `/etc/hosts` if the domain is not resolvable:

   ```bash
   sudo nano /etc/hosts
   # Add:
   127.0.0.1   yourlogin.42.fr
   ```

2. Open your browser and go to:

   - `https://yourlogin.42.fr`

3. You should see your **WordPress** site running behind **Nginx** with **HTTPS**.

---

## 9. Managing and Debugging

### 9.1. Check Container Status

```bash
docker ps
```

You should see at least:

- `nginx` container
- `wordpress` container
- `mariadb` container

### 9.2. Inspect Logs

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

### 9.3. Enter a Container Shell

```bash
docker exec -it <container_name> /bin/sh
# or
docker exec -it <container_name> /bin/bash
```

You can check configuration files, processes, permissions, etc.

### 9.4. Reset Everything

If you want a fresh install:

```bash
make clean
# Optionally remove host data directories if used:
rm -rf /home/$USER/data/wordpress/*
rm -rf /home/$USER/data/mariadb/*
make
```

---

## 10. Security and Good Practices

- **Custom images only**:  
  Don’t use prebuilt `wordpress`, `nginx:latest` without your Dockerfile.  
  Pin versions where possible (e.g., `alpine:3.18`).
- **No root where possible**:  
  Run services as non‑root users inside containers.
- **Least exposed ports**:  
  Usually only `443` is published to the host; DB stays internal.
- **Environment variables**:  
  Do not commit real passwords or sensitive environment data.
- **Volumes**:
  - Use them for persistence.
  - Do not store secrets in images; prefer secrets or env variables.

---

## 11. Extending the Project

Once the base stack works, you can extend it with:

- **Redis cache** for WordPress.
- **Adminer / phpMyAdmin** to inspect DB (if allowed by the subject).
- Better **TLS** setup: automatically renewing certificates with tools like `acme.sh` or Let’s Encrypt (in real-world scenarios).
- **Monitoring/logging**: Prometheus, Grafana, or basic tools to watch resources.

Each additional service:

1. Gets its own **Dockerfile** (no default images used directly).
2. Is defined in `docker-compose.yml`.
3. Is integrated carefully into the existing network and architecture.

---

## 12. Summary

Inception is a journey from:

- Basic Docker commands  
  → to  
- Building and orchestrating a small but realistic infrastructure.

This project teaches you to:

- Design separated, composable services.
- Use Dockerfiles and shell scripts to own your setup.
- Persist data with volumes.
- Secure and expose services through a reverse proxy (Nginx + TLS).
- Automate everything with Docker Compose + Makefile.

---

## 13. Useful Commands Reference

```bash
# Build and start the stack (check Makefile target name)
make
# or
make up

# Stop containers
make down

# Destroy containers + volumes (data loss)
make clean

# See running containers
docker ps

# See logs
docker compose -f srcs/docker-compose.yml logs -f

# Enter a container
docker exec -it <container> /bin/sh
```

---

If you want, share your current `docker-compose.yml` and `Makefile` and I can tailor this README even more precisely to your exact setup and target names.
