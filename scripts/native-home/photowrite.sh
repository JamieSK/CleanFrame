set -u
# Set My-Photos brightness (reversible). UID 901. Authorised by owner 2026-10-26.
# Edits ONLY the photo_brightness field inside db/screend/setting, preserving all other fields.
# Baseline photo_brightness = 5; to revert, set LEVEL=5 and re-run.
LEVEL=5
printf 'CLEANFRAME_HOME_INSPECT_BEGIN\n'
date 2>/dev/null || true
K=db/screend/setting
raw=$(buxton2ctl get system "$K" 2>/dev/null)
json=${raw#*String: }

echo '== BEFORE =='
printf '%s' "$json" | tr ',' '\n' | grep -iE 'photo_brightness|frame_brightness' || true

new=$(printf '%s' "$json" | sed -E "s/(\"photo_brightness\"[[:space:]]*:[[:space:]]*)-?[0-9]+/\1$LEVEL/")

# Safety: the edit must have changed exactly this, AND the object must still carry its other fields.
if [ "$new" = "$json" ]; then
  echo 'ABORT: photo_brightness pattern not matched / already set; no write'; printf 'CLEANFRAME_HOME_INSPECT_END\n'; exit 0
fi
if ! printf '%s' "$new" | grep -q 'frame_brightness' || ! printf '%s' "$new" | grep -q 'version'; then
  echo 'ABORT: other fields missing after edit; no write'; printf 'CLEANFRAME_HOME_INSPECT_END\n'; exit 0
fi

echo "== WRITE photo_brightness=$LEVEL =="
if vconftool set -t string "$K" "$new" -f; then echo 'SET via vconftool OK'; else
  if buxton2ctl set-string system "$K" "$new"; then echo 'SET via buxton2ctl OK'; else echo 'WRITE FAILED'; fi; fi

echo '== AFTER =='
buxton2ctl get system "$K" 2>&1 | tr ',' '\n' | grep -iE 'photo_brightness|frame_brightness' || true
printf 'CLEANFRAME_HOME_INSPECT_END\n'
