#!/bin/bash
set -euo pipefail

# === Setup awal ===
cd "$HOME/ink-of-days" || { echo "[ERROR] Gagal cd ke ink-of-days"; exit 1; }

# === Buat folder log harian ===
log_dir="$HOME/ink-of-days/logs"
mkdir -p "$log_dir"
logfile="$log_dir/activity-$(date +%Y-%m-%d).log"
exec > >(tee -a "$logfile") 2>&1

echo "=== Starting at $(date) ==="

# === Setup file libur ===
today=$(date +%u)  # 1 = Senin, 7 = Minggu
vacation_file=".days_off"
vacation_generated_flag=".days_off_generated"

# Jika belum ada file atau terakhir update lebih dari 6 hari
if [ ! -f "$vacation_file" ] || [ ! -f "$vacation_generated_flag" ] || [ "$(find "$vacation_generated_flag" -mtime +6)" ]; then
  echo "[INFO] Membuat ulang file hari libur..."
  echo -n > "$vacation_file"

  days_off_count=$((RANDOM % 2 + 1))  # 1–2 hari libur
  used_days=()

  while [ "${#used_days[@]}" -lt "$days_off_count" ]; do
    d=$((RANDOM % 7 + 1))
    if [[ ! " ${used_days[*]} " =~ " $d " ]]; then
      echo "$d" >> "$vacation_file"
      used_days+=("$d")
    fi
  done

  date > "$vacation_generated_flag"
fi

# === Cek apakah hari ini libur ===
if grep -qFx "$today" "$vacation_file"; then
  echo "🛌 Hari ini ($today) adalah hari libur commit. Santai dulu 😎"
  read -p "Tekan ENTER untuk keluar..."
  exit 0
fi

# === Randomizer ===
rand() { echo $((RANDOM % ($2 - $1 + 1) + $1)); }

roll=$(rand 1 100)
if [ "$roll" -le 60 ]; then
  commits_today=$(rand 4 9)
else
  if [ $((RANDOM % 2)) -eq 0 ]; then
    commits_today=$(rand 1 3)
  else
    commits_today=$(rand 10 11)
  fi
fi

echo "🛠️ Hari ini akan melakukan $commits_today commit."

# === Lakukan commit ===
for ((i = 1; i <= commits_today; i++)); do
  echo "Commit $i at $(date)" >> activity.log
  git add activity.log
  git commit -m "Auto commit $i on $(date)" || echo "[!] Commit $i gagal (tidak ada perubahan?)"
  sleep $(rand 1 5)
done

# === Push ke repo ===
git push && echo "✅ Push berhasil." || echo "❌ Push gagal."

echo "✅ Auto commit selesai pada $(date)"
read -p "Tekan ENTER untuk keluar..."
