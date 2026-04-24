#!/bin/bash

echo "=== CPU ==="
ps aux --sort=-%cpu | head -10

echo "=== FILA EXIM ==="
exim -bpc

echo "=== USO MAIL ==="
du -sh /home/*/mail 2>/dev/null | sort -hr | head

echo "=== USO SITES ==="
du -sh /home/*/public_html 2>/dev/null | sort -hr | head

