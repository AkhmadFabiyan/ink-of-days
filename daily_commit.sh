#!/bin/bash
set -euo pipefail

cd "$HOME/ink-of-days" || { echo "[ERROR] Gagal cd ke ink-of-days"; exit 1; }

log_dir="$HOME/ink-of-days/logs"
mkdir -p "$log_dir"
logfile="$log_dir/activity-$(date +%Y-%m-%d).log"
exec > >(tee -a "$logfile") 2>&1

echo "=== Starting at $(date) ==="

today=$(date +%u)
vacation_file=".days_off"
vacation_generated_flag=".days_off_generated"

# Buat file hari libur
if [ ! -f "$vacation_file" ] || [ ! -f "$vacation_generated_flag" ] || [ "$(find "$vacation_generated_flag" -mtime +6)" ]; then
  echo "[INFO] Membuat ulang file hari libur..."
  echo -n > "$vacation_file"

  days_off_count=$((RANDOM % 2 + 1))
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

if grep -qFx "$today" "$vacation_file"; then
  echo "🛌 Hari ini ($today) adalah hari libur commit. Santai dulu 😎"
  read -p "Tekan ENTER untuk keluar..."
  exit 0
fi

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

for ((i = 1; i <= commits_today; i++)); do
  echo "Commit $i at $(date)" >> activity.log
  git add activity.log
  git commit -m "Auto commit $i on $(date)" || echo "[!] Commit $i gagal (tidak ada perubahan?)"
  sleep $(rand 1 5)
done

echo "[INFO] Mencoba push ke repo..."
if git push; then
  echo "✅ Push berhasil."
else
  echo "❌ Push gagal. Coba melakukan stash lalu pull --rebase..."

  stash_applied=false
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    git stash push -u -m "Auto stash sebelum rebase"
    stash_applied=true
  fi

  if git pull --rebase; then
    echo "[INFO] Pull --rebase berhasil. Mencoba push ulang..."
    if git push; then
      echo "✅ Push berhasil setelah rebase."
    else
      echo "❌ Push tetap gagal setelah rebase. Harap cek manual."
    fi

    # Pop stash jika ada
    if [ "$stash_applied" = true ]; then
      if git stash pop; then
        echo "[INFO] Stash berhasil dipulihkan kembali."
      else
        echo "[WARNING] Gagal menerapkan stash. Perlu di-handle manual."
      fi
    fi
  else
    echo "❌ Pull --rebase gagal total. Perlu intervensi manual."
  fi
fi

# Tambahan: commit file baru/hapus otomatis
# Stage file untracked dan perubahan penghapusan
git add -A
if git diff --cached --quiet; then
  echo "🧹 Tidak ada perubahan tambahan yang perlu di-commit."
else
  git commit -m "Auto commit tambahan setelah push (add/remove files)"
  echo "✅ Commit tambahan berhasil."
fi

echo "✅ Auto commit selesai pada $(date)"
read -p "Tekan ENTER untuk keluar..."
