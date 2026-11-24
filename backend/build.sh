#!/usr/bin/env bash
set -o errexit
pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate --no-input
# Demo foydalanuvchilar (parol: demo12345). Haqiqiy ishga o‘tganda SEED_DEMO=0 qiling va parollarni almashtiring.
if [ "$SEED_DEMO" = "1" ]; then python manage.py seed_demo; fi
python manage.py ensure_admin
