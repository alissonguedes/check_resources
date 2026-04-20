#!/bin/bash

# ===== CPU =====
read model mhz socket cores tpc threads <<< $(lscpu | awk -F: '
/Model name/ {gsub(/^[ \t]+/, "", $2); model=$2}
/CPU MHz/ {gsub(/^[ \t]+/, "", $2); mhz=$2}
/Socket\(s\)/ {gsub(/^[ \t]+/, "", $2); socket=$2}
/Core\(s\) per socket/ {gsub(/^[ \t]+/, "", $2); cores=$2}
/Thread\(s\) per core/ {gsub(/^[ \t]+/, "", $2); tpc=$2}
/^CPU\(s\)/ {gsub(/^[ \t]+/, "", $2); threads=$2}
END {print model, mhz, socket, cores, tpc, threads}')

# GHz com vírgula
if [ -n "$mhz" ]; then
  freq=$(awk "BEGIN {printf \"%.2f\", $mhz/1000}")
  freq=$(echo $freq | sed 's/\./,/')
else
  freq="-"
fi

# ===== MEMÓRIA =====
read ram swap <<< $(free -h | awk '
/Mem:/ {ram=$2}
/Swap:/ {swap=$2}
END {print ram, swap}')

# padronizar Gi + vírgula
ram=$(echo $ram | sed 's/G/Gi/; s/\./,/')
swap=$(echo $swap | sed 's/G/Gi/; s/\./,/')

# ===== DISCO ROOT =====
read rt ru rf rp <<< $(df -h | awk '$NF=="/" {print $2, $3, $4, $5}')

# converter ponto → vírgula (somente números com decimal)
rt=$(echo $rt | sed 's/\./,/')
ru=$(echo $ru | sed 's/\./,/')
rf=$(echo $rf | sed 's/\./,/')

# ===== DISCO BACKUP =====
backup=$(df -h | awk '$NF=="/backup" {print $2,$3,$4,$5}')

if [ -n "$backup" ]; then
  bt=$(echo $backup | awk '{print $1}' | sed 's/\./,/')
  bu=$(echo $backup | awk '{print $2}' | sed 's/\./,/')
  bf=$(echo $backup | awk '{print $3}' | sed 's/\./,/')
  bp=$(echo $backup | awk '{print $4}')
else
  bt="-"; bu="-"; bf="-"; bp="-"
fi

# ===== INFO =====
host=$(hostname -f)
ip=$(hostname -I | awk '{print $1}')

# ===== DESCRIÇÃO DE SERVIÇOS =====
services="---Descrição dos serviços---"

# ===== SAÍDA FINAL =====
echo -e "$host\t$ip\t$services\t$model\t$freq\t$socket\t$cores\t$tpc\t$threads\t$ram\t$swap\t$rt\t$ru\t$rf\t$rp\t$bt\t$bu\t$bf\t$bp"
