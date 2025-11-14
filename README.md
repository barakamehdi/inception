# Inception

**42 School System Administration Project**

This project sets up a small infrastructure using Docker Compose with NGINX, WordPress, and MariaDB.

## 📋 Project Structure

```
inception/
├── Makefile
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

## 🚀 Setup Instructions

### 1. Prerequisites

- Docker and Docker Compose installed
- Virtual Machine (recommended)
- Root/sudo access for creating data directories

### 2. Configure Hosts File

Add this line to your `/etc/hosts` file:

```bash
127.0.0.1 elbaraka.42.fr
```

### 3. Create Data Directories

```bash
sudo mkdir -p /home/elbaraka/data/wordpress
sudo mkdir -p /home/elbaraka/data/mariadb
```

### 4. Configure Environment Variables

Edit `srcs/.env` and update passwords and credentials as needed.

### 5. Build and Run

```bash
make
```

## 📝 Available Commands

- `make` or `make all` - Setup, build, and start all containers
- `make build` - Build Docker images
- `make up` - Start containers
- `make down` - Stop and remove containers
- `make stop` - Stop containers
- `make start` - Start stopped containers
- `make clean` - Remove containers and images
- `make fclean` - Full cleanup including data
- `make re` - Rebuild everything
- `make logs` - View container logs
- `make ps` - List running containers

## 🌐 Access

Once running, access your WordPress site at:
- **https://elbaraka.42.fr**

## 📦 Services

- **NGINX**: Reverse proxy with TLSv1.2/1.3 (port 443)
- **WordPress**: CMS with php-fpm
- **MariaDB**: Database server

## 👤 Default Credentials

**Admin User:**
- Username: `elbaraka`
- Password: (check `.env` file)

**Editor User:**
- Username: `wp_editor`
- Password: (check `.env` file)

## ⚠️ Important Notes

- Change all passwords in `.env` before production use
- Never commit `.env` file to git
- Data persists in `/home/elbaraka/data/`
- All containers restart automatically on crash

## 📚 Documentation

- [Docker Documentation](https://docs.docker.com/)
- [WordPress Documentation](https://wordpress.org/support/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)

## 🎓 42 Network

**Login:** elbaraka.42.fr  
**Project:** Inception

---

Made with ❤️ for 42 School
