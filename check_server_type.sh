#!/bin/bash

echo "===== DETECÇÃO DE APLICAÇÕES ====="

tipo=()

# ===== PORTAS =====
ports=$(ss -tulpn 2>/dev/null)

# ===== PROCESSOS =====
procs=$(ps aux)

# ===== DOCKER =====
docker_running=$(command -v docker >/dev/null && docker ps --format '{{.Image}}' 2>/dev/null)

# ===== WEB =====
if echo "$ports" | grep -qE ':80|:443'; then
    if echo "$procs" | grep -q nginx; then
        tipo+=("Web (Nginx)")
    elif echo "$procs" | grep -q httpd; then
        tipo+=("Web (Apache)")
    else
        tipo+=("Web (porta aberta)")
    fi
fi

# ===== PHP =====
if echo "$procs" | grep -q php-fpm; then
    tipo+=("PHP")
fi

# ===== NODE =====
if echo "$procs" | grep -q node; then
    tipo+=("Node.js")
fi

# ===== PYTHON =====
if echo "$procs" | grep -qE 'gunicorn|uvicorn|python'; then
    tipo+=("Python App")
fi

# ===== JAVA =====
if echo "$procs" | grep -q java; then
    tipo+=("Java App")
fi

# ===== BANCO =====
if echo "$ports" | grep -q ':3306'; then
    tipo+=("MySQL/MariaDB")
fi

if echo "$ports" | grep -q ':5432'; then
    tipo+=("PostgreSQL")
fi

if echo "$ports" | grep -q ':6379'; then
    tipo+=("Redis")
fi

# ===== EMAIL =====
if echo "$ports" | grep -qE ':25|:465|:587'; then
    tipo+=("Servidor de Email")
fi

# ===== FTP =====
if echo "$ports" | grep -q ':21'; then
    tipo+=("FTP")
fi

# ===== DOCKER =====
if [ -n "$docker_running" ]; then
    tipo+=("Docker")
fi

# ===== WORDPRESS DETECÇÃO =====
if find /var/www /home -maxdepth 3 -name "wp-config.php" 2>/dev/null | grep -q .; then
    tipo+=("WordPress")
fi

# ===== RESULTADO =====
if [ ${#tipo[@]} -eq 0 ]; then
    echo "Nenhuma aplicação identificada"
else
    echo "Aplicações detectadas:"
    printf ' - %s\n' "${tipo[@]}"
fi
