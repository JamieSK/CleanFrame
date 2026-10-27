set -u
# Art Mode brightness RESTORE — writes db/screend/settings/frame_backlight_info back to the exact
# captured baseline (every lux bucket osd_level 0; user_controled 1 for lux 0..17, 2 for 18..20).
# Mirrors .local/art-brightness/baseline.txt. UID 901.
printf 'CLEANFRAME_HOME_INSPECT_BEGIN\n'
date 2>/dev/null || true
KEY=db/screend/settings/frame_backlight_info
echo '== BEFORE restore =='
buxton2ctl get system "$KEY" 2>&1 | head -5

json='['
l=0
while [ "$l" -le 20 ]; do
  uc=1; [ "$l" -ge 18 ] && uc=2
  [ "$l" -gt 0 ] && json="$json,"
  json="$json{\"lux\":$l,\"osd_level\":0,\"user_controled\":$uc}"
  l=$((l+1))
done
json="$json]"

echo '== RESTORE baseline (all osd_level 0; auto_brightness 1; brightness 0) =='
if vconftool set -t string "$KEY" "$json" -f; then
  echo 'RESTORE curve via vconftool OK'
else
  if buxton2ctl set-string system "$KEY" "$json"; then echo 'RESTORE curve via buxton2ctl OK'; else echo 'RESTORE FAILED — reset Art brightness via the TV slider instead'; fi
fi
vconftool set -t int db/screend/settings/auto_brightness 1 -f 2>&1 || buxton2ctl set-int32 system db/screend/settings/auto_brightness 1 2>&1 || true
vconftool set -t int db/screend/settings/brightness 0 -f 2>&1 || buxton2ctl set-int32 system db/screend/settings/brightness 0 2>&1 || true
vconftool set -t bool db/menu/system/auto_screen_dimming 1 -f 2>&1 || buxton2ctl set-bool system db/menu/system/auto_screen_dimming true 2>&1 || true
vconftool set -t int db/art-app/color_sensor 1 -f 2>&1 || buxton2ctl set-int32 system db/art-app/color_sensor 1 2>&1 || true
echo '== AFTER restore =='
buxton2ctl get system "$KEY" 2>&1 | head -5
buxton2ctl get system db/screend/settings/auto_brightness 2>&1
printf 'CLEANFRAME_HOME_INSPECT_END\n'
