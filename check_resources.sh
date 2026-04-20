#!/bin/bash

CPUINFO="/proc/cpuinfo"

# ===== CPU =====

# Modelo
model=$(awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' "$CPUINFO")

# Frequência média
mhz=$(awk -F: '/cpu MHz/ {sum+=$2; n++} END {if(n>0) print sum/n}' "$CPUINFO")

if [ -n "$mhz" ]; then
  freq=$(awk "BEGIN {printf \"%.2f\", $mhz/1000}")
  freq=${freq/./,}
else
  freq="-"
fi

# Threads totais (confiável)
threads=$(grep -c "^processor" "$CPUINFO")

# Sockets
socket=$(awk -F: '/physical id/ {print $2}' "$CPUINFO" | sort -u | wc -l)
[ "$socket" -eq 0 ] && socket=1

# ===== MAPEAR CORES E THREADS POR CORE =====

core_threads=$(awk '
/^physical id/ {p=$4}
/^core id/ {c=$4}
/^processor/ {cpu=$3}
/^$/ {
  if (p == "") p=0
  if (c == "") c=cpu   # fallback: cada CPU vira um "core"

  key=p "-" c
  core[key]++

  p=""; c=""
}
END {
  for (k in core) print core[k]
}
' "$CPUINFO")

# ===== CORES =====
cores=$(echo "$core_threads" | wc -l)

# Fallback (caso extremo)
if [ "$cores" -le 1 ]; then
  cores_per_socket=$(awk -F: '/cpu cores/ {print $2; exit}' "$CPUINFO" | xargs)
  if [ -n "$cores_per_socket" ]; then
    cores=$((cores_per_socket * socket))
  else
    cores=$threads
  fi
fi

# ===== DETECÇÃO HÍBRIDA =====
types=$(echo "$core_threads" | sort -u | wc -l)

if [ "$types" -gt 1 ]; then
  # Ex: 4x1 2x2
  tpc_desc=$(echo "$core_threads" | sort | uniq -c | awk '{print $1"x"$2}' | xargs)
else
  # homogêneo
  threads_per_core=$(awk "BEGIN {printf \"%.2f\", $threads/$cores}")
  tpc_desc=$(echo $threads_per_core | sed 's/\./,/')
fi

# ===== MEMÓRIA =====
read ram swap <<< $(free -h | awk '
/Mem:/ {ram=$2}
/Swap:/ {swap=$2}
END {print ram, swap}')

# ===== DISCO ROOT =====
read rt ru rf rp <<< $(df -h | awk '$NF=="/" {print $2, $3, $4, $5}')

rt=${rt/./,}
ru=${ru/./,}
rf=${rf/./,}

# ===== DISCO BACKUP =====
backup=$(df -h | awk '$NF=="/backup" {print $2,$3,$4,$5}')

if [ -n "$backup" ]; then
  bt=$(echo "$backup" | awk '{print $1}' | sed 's/\./,/')
  bu=$(echo "$backup" | awk '{print $2}' | sed 's/\./,/')
  bf=$(echo "$backup" | awk '{print $3}' | sed 's/\./,/')
  bp=$(echo "$backup" | awk '{print $4}')
else
  bt="-"; bu="-"; bf="-"; bp="-"
fi

# ===== INFO =====
host=$(hostname -f)
ip=$(hostname -I | awk '{print $1}')

services="---Descrição dos serviços---"

# ===== SAÍDA =====
echo -e "$host\t$ip\t$services\t$model\t$freq\t$socket\t$cores\t$tpc_desc\t$threads\t$ram\t$swap\t$rt\t$ru\t$rf\t$rp\t$bt\t$bu\t$bf\t$bp"
