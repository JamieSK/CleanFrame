set -u
# Diagnose the dark-room override source. UID 901, READ-ONLY.
printf 'CLEANFRAME_HOME_INSPECT_BEGIN\n'
date 2>/dev/null || true
echo '== screend state (did auto_brightness stick at 0?) =='
for k in db/screend/settings/auto_brightness db/screend/settings/brightness db/screend/ambient_status; do
  printf '%-40s => ' "$k"; buxton2ctl get system "$k" 2>&1 | tr '\n' ' '; printf '\n'
done
echo -n 'frame_brightness (live applied) => '
buxton2ctl get system db/screend/setting 2>&1 | tr ',' '\n' | grep -i 'frame_brightness' | tr '\n' ' '; echo

echo '== other auto-dimming / ambient features that could override in the dark =='
for k in \
 db/menu/system/auto_screen_dimming \
 db/last/enable/ai_brightness \
 db/menu/system/eco_solution/eco_sensor/value \
 db/menu/system/eco_solution/eco_sensor/min_backlight \
 db/menu/system/eco_solution/min_backlight \
 db/userpresence/auto_dimming ; do
  printf '%-48s => ' "$k"; buxton2ctl get system "$k" 2>&1 | tr '\n' ' '; printf '\n'
done

echo '== AVOC AMBIENT picture-quality (current values) =='
AV=/opt/dbspace/.avoc.db; VT=/tmp/cf-dx-$$.db
if cp "$AV" "$VT" 2>/dev/null; then
  cp "$AV-wal" "$VT-wal" 2>/dev/null || true; cp "$AV-shm" "$VT-shm" 2>/dev/null || true
  sqlite3 "$VT" "SELECT d.setting_name||'='||s.current_value FROM SETTING s JOIN DICT_SETTINGS d ON d.setting_id=s.setting_id JOIN DICT_PICTURE_MODE pm ON pm.picture_mode_id=s.picture_mode WHERE pm.picture_mode_name='TZTV_PICTURE_MODE_AMBIENT' AND d.setting_name IN ('AVOCD_SETTING_BACKLIGHT','AVOCD_SETTING_ECO_SENSOR','AVOCD_SETTING_ECO_SENSOR_MINIMAL_BACKLIGHT','AVOCD_SETTING_AUTO_BRIGHTNESS_REDUCTION','AVOCD_SETTING_SMART_LED');" 2>&1 | head -10 || true
  rm -f "$VT" "$VT-wal" "$VT-shm"
fi
printf 'CLEANFRAME_HOME_INSPECT_END\n'
