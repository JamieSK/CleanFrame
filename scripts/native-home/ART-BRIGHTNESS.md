# Art Mode brightness experiment — abandoned

Recorded 27 October 2026 on the owner's QE43LS03FAUXXH (firmware T-PTMFDEUC-0090-1301.0). This experiment did not succeed. These scripts are kept for reference, not for routine use.

## Goal

Set Art Mode to a fixed brightness beyond the range of the TV's own Art Mode brightness setting, and keep that level steady in a dark room.

## What was tried

All writes ran over the existing `run.py` transport as the TV's UID 901, with an exact-value baseline captured first and a restore script ready.

| Script | Purpose | Writes |
| --- | --- | --- |
| `artbright.sh` | Read the `screend` brightness keys, automatic dimming keys and a temporary copy of the AVOC picture database | None |
| `artwrite.sh` | Turn off automatic brightness, the art colour sensor and automatic screen dimming, then write a flat `db/screend/settings/frame_backlight_info` curve at `LEVEL` | vconf/buxton keys |
| `artrestore.sh` | Restore the captured baseline: every curve bucket at `osd_level` 0, and automatic brightness, screen dimming and colour sensor back on | vconf/buxton keys |
| `photowrite.sh` | Change only `photo_brightness` inside `db/screend/setting` (My Photos) | One field; baseline 5 |

Run one with `python3 scripts/native-home/run.py <name>`, where `<name>` is the script name without `.sh`. The runner accepts these names next to `query`, `apply`, `restore` and `inspect`. None of them use the compiled native Home helper.

## Why it failed

- **Writing the flat curve did change the panel.** Once automatic brightness and the sensors were off, the fixed level held in any room light.
- **Only whole numbers take effect.** The curve stores fractional values such as -4.5, but the panel uses only the whole-number part. -4, -4.5, -4.8 and -4.9 all looked the same.
- **The levels are too coarse.** On this TV, `osd_level` 0 down to -4 looked the same. -5 was a sudden step to much dimmer. There is no level between -4 and -5, which is where the owner wanted to be, and neither -4 nor -5 was acceptable.
- **The only other control was too risky.** The other way to change brightness is the AVOC `AMBIENT` backlight setting (50 on this TV), held by the `avocd` daemon. It has no command-line interface. The daemon keeps the live value in memory and holds `/opt/dbspace/.avoc.db` open, so a direct edit could be ignored or overwritten. That database also stores picture settings for every picture mode, not only Art Mode, and has no simple one-line revert. A change might also have no visible effect, because the `screend` level may override it. This was **not attempted**.

## Final state

`artrestore` ran on 27 October 2026, 10:36. Its output confirmed every curve bucket at `osd_level` 0 and `auto_brightness` = 1. My Photos `photo_brightness` reads 5, its baseline. The TV's brightness behaviour matches the state before the experiment. Saved outputs and the baseline are kept in ignored `.local/native-home/` and `.local/art-brightness/`.

## If this is revisited

Treat any write as a separate task with the owner's explicit authority. Capture an exact-value baseline and have a tested restore ready first, then confirm the result visually on the TV. The undocumented keys used here are Samsung internals on one firmware. They may change or behave differently on other models.
