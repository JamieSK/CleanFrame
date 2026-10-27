set -u
# Art Mode FIXED brightness (reversible). UID 901. Authorised by owner.
# Working recipe: disable the ambient sensors/dimming so a fixed level holds in any room light,
# then write a FLAT frame_backlight_info curve at LEVEL. LEVEL may be fractional (test if screend
# accepts half-steps); the Int scalar below is rounded toward zero.
LEVEL=-5
printf 'CLEANFRAME_HOME_INSPECT_BEGIN\n'
date 2>/dev/null || true
KEY=db/screend/settings/frame_backlight_info
SCALAR=${LEVEL%.*}   # integer part for the Int32 scalar (curve is the authoritative driver)

echo '== BEFORE =='
buxton2ctl get system db/screend/setting 2>&1 | tr ',' '\n' | grep -i 'frame_brightness' || true

echo '== disable ambient sensors / auto-dimming (so the level holds constant) =='
vconftool set -t int  db/screend/settings/auto_brightness 0 -f 2>&1 || buxton2ctl set-int32 system db/screend/settings/auto_brightness 0 2>&1 || true
vconftool set -t int  db/art-app/color_sensor 0 -f 2>&1 || buxton2ctl set-int32 system db/art-app/color_sensor 0 2>&1 || true
vconftool set -t bool db/menu/system/auto_screen_dimming 0 -f 2>&1 || buxton2ctl set-bool system db/menu/system/auto_screen_dimming false 2>&1 || true
vconftool set -t int  db/screend/settings/brightness "$SCALAR" -f 2>&1 || buxton2ctl set-int32 system db/screend/settings/brightness "$SCALAR" 2>&1 || true

# Flat curve at LEVEL (emit value directly so fractional values pass through verbatim).
json='['
l=0
while [ "$l" -le 20 ]; do
  uc=1; [ "$l" -ge 18 ] && uc=2
  [ "$l" -gt 0 ] && json="$json,"
  json="$json{\"lux\":$l,\"osd_level\":$LEVEL,\"user_controled\":$uc}"
  l=$((l+1))
done
json="$json]"

echo "== WRITE flat osd_level=$LEVEL (all buckets) =="
if vconftool set -t string "$KEY" "$json" -f; then echo 'SET via vconftool OK'; else
  if buxton2ctl set-string system "$KEY" "$json"; then echo 'SET via buxton2ctl OK'; else echo 'WRITE FAILED'; fi; fi

echo '== AFTER (what screend actually stored — reveals if the fraction survived) =='
buxton2ctl get system db/screend/setting 2>&1 | tr ',' '\n' | grep -i 'frame_brightness' || true
buxton2ctl get system "$KEY" 2>&1 | tr -d '\n ' | sed 's/},{/}\n{/g' | grep -oE '"lux":0,"osd_level":[-0-9.]+' || true
printf 'CLEANFRAME_HOME_INSPECT_END\n'
