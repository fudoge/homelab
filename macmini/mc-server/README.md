## MINECRAFT SERVER

- [https://hub.docker.com/r/itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server)
- [https://docker-minecraft-server.readthedocs.io/en/latest/](https://docker-minecraft-server.readthedocs.io/en/latest/)

**Quickstart**

```bash
cp example.env .env
```

whitelists, ops are comma-separated.

```bash
mkdir mc-data
```

**UP(Run Your Server)**

```bash
docker compose up -d
```

**DOWN**

```bash
docker compose down
```

## How to run server 24/7 in MacOS

```bash
caffeinate -i -s docker compose up
```

or..

```bash
./mac-run.sh
```
