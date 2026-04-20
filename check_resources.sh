#!/bin/bash

# CPU
read model mhz socket cores tpc threads <<< $(lscpu | awk -F: '
/Model name/ {gsub(/^[ \t]+/, "", $2); model=$2}
/CPU Mhz/ {mhz=$2}
/Socket\(s\)/ {gsub(/^[ \t]+/, "", $2); socket=$2}
/Core\(s\) per socket/ {gsub(/^[ \t]+/, "", $2); cores=$2}
/Thread\(s\) per core/ {gsub(/^[ \t]+/, "", $2); tpc=$2}
/^CPU\(s\)/ {gsub(/^[ \t]+/, "", $2); threads=$2}
END {print model, mhz, socket, cores, tpc, threads}')

# Converter MHz → GHz (fallback caso não exista)
#if [ -n "$mhz" ]; then
#  freq=$(awk "BEGIN {printf \"%.2f\", $mhz/1000}")
#else
#  freq="N/A"
#fi

# Memória (GB)
read ram swap <<< $(free -h | awk '
/Mem:/ {ram=$2}
/Swap:/ {swap=$2}
END {print ram, swap}')

# Disco raiz
read rt ru rf rp <<< $(df -h | awk '$NF=="/" {
#  gsub(/%/,"",$5);
  print $2, $3, $4, $5
}')

# Disco backup
backup=$(df -h | awk '$NF=="/backup" {
#  gsub(/%/,"",$5);
  print $2";"$3";"$4";"$5
}')

if [ -n "$backup" ]; then
  bt=$(echo $backup | cut -d';' -f1)
  bu=$(echo $backup | cut -d';' -f2)
  bf=$(echo $backup | cut -d';' -f3)
  bp=$(echo $backup | cut -d';' -f4)
else
  bt="N/A"; bu="N/A"; bf="N/A"; bp="N/A"
fi

# Info adicionais
host=$(hostname)
ip=$(hostname -I | awk '{print $1}')
desc="N/A"

# Linha CSV (SEM cabeçalho e com ;)
echo "$host;$ip;$desc;$model;$freq;$socket;$cores;$tpc;$threads;$ram;$swap;$rt;$ru;$rf;$rp;$bt;$bu;$bf;$bp"

