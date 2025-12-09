# Keycloak POC

A simple Keycloak proof-of-concept setup using Docker Compose for local development and testing.

## Overview

This setup provides a complete Keycloak instance with PostgreSQL as the database backend. It's configured for development mode and runs entirely in Docker containers.

**Note:** This is an ephemeral setup - all data is stored in container volumes and will be lost when containers are removed.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Start the services:
   ```bash
   docker-compose up -d
   ```

2. Wait for services to be healthy (usually 20-30 seconds)

3. Access Keycloak at: http://localhost:8080

## Default Credentials

### Keycloak Admin Console
- **URL:** http://localhost:8080
- **Username:** `admin`
- **Password:** `admin`

### PostgreSQL Database
- **Host:** `localhost` (or `postgres` from within containers)
- **Port:** `5432` (internal only, not exposed to host)
- **Database:** `keycloak`
- **Username:** `keycloak`
- **Password:** `keycloak`

## Services

### Keycloak
- **Image:** quay.io/keycloak/keycloak:latest
- **Port:** 8080
- **Mode:** Development (`start-dev`)
- **Features:** HTTP enabled, proxy headers supported, non-strict hostname checking

### PostgreSQL
- **Image:** postgres:16-alpine
- **Health checks:** Configured with 5 retries
- **Restart policy:** unless-stopped

## Management Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
docker-compose logs -f
```

### Restart services
```bash
docker-compose restart
```

## Notes

- This setup is intended for **development/testing only** and is not production-ready
- Data is ephemeral - removing containers will delete all data
- Admin credentials should be changed for any non-local usage
- Keycloak runs in development mode with relaxed security settings
