#!/usr/bin/env python3
"""Keep the GNOME display scale pinned to a fixed value.

Why: this VM runs under Parallels, which presents one virtual display whose
resolution mode changes whenever the VM window is moved between host displays
(the mode list is swapped host-side). On each such switch mutter's stored
monitor config no longer matches, and its fallback lands on scale 1.0,
resetting the GNOME UI scale. This service watches mutter's display
configuration and re-applies the configured scale right after such changes.

Notes on scales:
  * Mutter only accepts scales that produce whole-pixel logical sizes; each
    mode advertises its valid scale list. The configured target is snapped to
    the closest supported value (e.g. on a 3024x1964 MacBook panel 1.5 is not
    mathematically possible; the closest supported value is ~1.3333).
  * Corrections use ApplyMonitorsConfig with method=TEMPORARY so no
    "Keep display settings?" dialog appears.
  * After a correction, ~/.config/monitors.xml is synced to the applied
    configuration (mutter reads that file only at session start), so logging
    in on the same display starts with the right scale immediately.

Configuration: ~/.config/fixed-display-scale.conf  (key = value lines)
  scale=1.5          target UI scale
  enabled=yes        set to "no" to pause enforcement
  debounce-ms=600    settle time after the last display change
  mode-<W>x<H>=<v>   per-resolution target override, e.g. mode-3024x1964=2
"""

import os
import time

if not os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
    runtime = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
    os.environ['DBUS_SESSION_BUS_ADDRESS'] = f'unix:path={runtime}/bus'

import subprocess

from gi.repository import Gio, GLib

DC = 'org.gnome.Mutter.DisplayConfig'
PATH = '/org/gnome/Mutter/DisplayConfig'
CONF_PATH = os.path.expanduser('~/.config/fixed-display-scale.conf')
LOG_PATH = os.path.expanduser('~/.local/state/fixed-display-scale.log')
MONITORS_XML = os.path.expanduser('~/.config/monitors.xml')

DEFAULTS = {
    'enabled': 'yes',
    'scale': '1.5',
    'debounce-ms': '600',
}
EPS = 1e-6


def log(msg):
    line = f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}"
    try:
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        if os.path.exists(LOG_PATH) and os.path.getsize(LOG_PATH) > 512 * 1024:
            os.truncate(LOG_PATH, 0)
        with open(LOG_PATH, 'a') as f:
            f.write(line + '\n')
    except OSError:
        pass
    print(line, flush=True)


def read_config():
    cfg = dict(DEFAULTS)
    try:
        with open(CONF_PATH) as f:
            for raw in f:
                line = raw.strip()
                if not line or line.startswith('#') or '=' not in line:
                    continue
                key, val = line.split('=', 1)
                cfg[key.strip().lower()] = val.strip()
    except OSError:
        pass
    return cfg


def ensure_fractional_scaling():
    """Make sure the scale-monitor-framebuffer experimental feature is on."""
    try:
        out = subprocess.check_output(
            ['gsettings', 'get', 'org.gnome.mutter', 'experimental-features'],
            text=True).strip()
        if out.startswith('[') and out.endswith(']'):
            inner = out[1:-1].strip()
            items = [x.strip().strip('\'"') for x in inner.split(',')] if inner else []
        else:
            items = []
        if 'scale-monitor-framebuffer' in items:
            return
        items.append('scale-monitor-framebuffer')
        val = '[' + ', '.join(f"'{x}'" for x in items) + ']'
        subprocess.check_call(
            ['gsettings', 'set', 'org.gnome.mutter', 'experimental-features', val])
        log('re-enabled scale-monitor-framebuffer experimental feature')
    except Exception as e:  # noqa: BLE001
        log(f'could not check experimental-features: {e!r}')


class Watcher:
    def __init__(self):
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.debounce_id = None
        self.corrections = []
        self.backoff_until = 0.0
        self.backoff_logged = False

    # ---------- state ----------

    def get_state(self):
        res = self.bus.call_sync(DC, PATH, DC, 'GetCurrentState', None, None,
                                 Gio.DBusCallFlags.NONE, -1, None)
        serial, monitors, logical, props = res.unpack()

        conn_info = {}     # connector -> (vendor, product, serial)
        conn_mode = {}     # connector -> current mode id
        mode_scales = {}   # (connector, mode id) -> supported scales
        mode_key = {}      # (connector, mode id) -> "WxH"
        mode_dims = {}     # (connector, mode id) -> (w, h, refresh)
        for m in monitors:
            if len(m) == 3:
                spec, modes, _mprops = m
                conn, vendor, product, ser = spec
            else:
                conn, vendor, product, ser, modes, _mprops = m
            conn_info[conn] = (vendor, product, ser)
            for mode in modes:
                mid, w, h, refresh = mode[0], mode[1], mode[2], mode[3]
                scales = mode[5] if len(mode) >= 6 else ()
                mprops = mode[-1]
                if isinstance(mprops, dict) and mprops.get('is-current'):
                    conn_mode[conn] = mid
                    mode_scales[(conn, mid)] = tuple(scales)
                    mode_key[(conn, mid)] = f'{w}x{h}'
                    mode_dims[(conn, mid)] = (w, h, refresh)

        return {
            'serial': serial,
            'conn_info': conn_info,
            'conn_mode': conn_mode,
            'mode_scales': mode_scales,
            'mode_key': mode_key,
            'mode_dims': mode_dims,
            'logical': list(logical),
            'layout_mode': props.get('layout-mode', 1),
        }

    def desired_for(self, cfg, mode_key_str, scales):
        if not scales:
            return None
        target = cfg.get(f'mode-{mode_key_str}') or cfg.get('scale') or '1.5'
        try:
            target = float(target)
        except (TypeError, ValueError):
            target = 1.5
        return min(scales, key=lambda s: abs(s - target))

    @staticmethod
    def build_lm_variant(lm, desired_scale, conn_mode):
        x, y, _scale, transform, primary, mons = lm[:6]
        entries = []
        for mon in mons:
            conn = mon[0]
            mode_id = conn_mode.get(conn)
            if mode_id is None:
                return None
            entries.append((conn, mode_id, {}))
        return GLib.Variant('(iiduba(ssa{sv}))',
                            (int(x), int(y), float(desired_scale),
                             int(transform), bool(primary), entries))

    # ---------- persistence ----------

    def sync_monitors_xml(self, applied, conn_info, mode_dims):
        """Rewrite ~/.config/monitors.xml to match the applied configuration.

        Mutter only reads this file at session start; syncing it keeps the
        next login on the same display at the right scale from second zero.
        """
        lines = ['<monitors version="2">', '  <configuration>',
                 '    <layoutmode>logical</layoutmode>']
        for item in applied:
            lines.append('    <logicalmonitor>')
            lines.append(f'      <x>{item["x"]}</x>')
            lines.append(f'      <y>{item["y"]}</y>')
            lines.append(f'      <scale>{item["scale"]!r}</scale>')
            if item['primary']:
                lines.append('      <primary>yes</primary>')
            for conn, mode_id in item['monitors']:
                vendor, product, ser = conn_info.get(conn, ('unknown', 'unknown', 'unknown'))
                w, h, refresh = mode_dims.get((conn, mode_id), (0, 0, 0.0))
                lines.append('      <monitor>')
                lines.append('        <monitorspec>')
                lines.append(f'          <connector>{conn}</connector>')
                lines.append(f'          <vendor>{vendor}</vendor>')
                lines.append(f'          <product>{product}</product>')
                lines.append(f'          <serial>{ser}</serial>')
                lines.append('        </monitorspec>')
                lines.append('        <mode>')
                lines.append(f'          <width>{w}</width>')
                lines.append(f'          <height>{h}</height>')
                lines.append(f'          <rate>{refresh:.6f}</rate>')
                lines.append('        </mode>')
                lines.append('      </monitor>')
            lines.append('    </logicalmonitor>')
        lines.append('  </configuration>')
        lines.append('</monitors>')
        xml = '\n'.join(lines) + '\n'
        tmp = MONITORS_XML + '.tmp'
        try:
            existing_mode = None
            if os.path.exists(MONITORS_XML):
                existing_mode = os.stat(MONITORS_XML).st_mode & 0o777
            with open(tmp, 'w') as f:
                f.write(xml)
            if existing_mode is not None:
                os.chmod(tmp, existing_mode)
            os.replace(tmp, MONITORS_XML)
            log(f'synced {MONITORS_XML} to the applied configuration')
        except OSError as e:
            log(f'could not sync monitors.xml: {e!r}')

    # ---------- correction ----------

    def correct(self, reason):
        try:
            cfg = read_config()
            if str(cfg.get('enabled', 'yes')).lower() in ('no', 'false', '0', 'off'):
                return
            now = time.monotonic()
            if now < self.backoff_until:
                return

            st = self.get_state()

            variants = []
            applied = []
            changes = []
            for lm in st['logical']:
                mons = lm[5] if len(lm) >= 6 else ()
                if not mons:
                    continue
                conn = mons[0][0]
                mode_id = st['conn_mode'].get(conn)
                if not mode_id:
                    continue
                scales = st['mode_scales'].get((conn, mode_id), ())
                mk = st['mode_key'].get((conn, mode_id), '?')
                desired = self.desired_for(cfg, mk, scales)
                if desired is None:
                    continue
                current = float(lm[2])
                if abs(current - desired) >= EPS:
                    changes.append(f'{conn} {mk}: {current} -> {desired}')
                variant = self.build_lm_variant(lm, desired, st['conn_mode'])
                if variant is None:
                    continue
                variants.append(variant)
                applied.append({
                    'x': int(lm[0]), 'y': int(lm[1]), 'scale': desired,
                    'primary': bool(lm[4]),
                    'monitors': [(mon[0], st['conn_mode'][mon[0]]) for mon in mons
                                 if mon[0] in st['conn_mode']],
                })

            if not changes:
                if reason == 'startup':
                    log('startup check: scale already at target')
                return

            # anti-flap guard: if something keeps fighting us, back off
            now = time.monotonic()
            self.corrections = [t for t in self.corrections if t > now - 30]
            self.corrections.append(now)
            if len(self.corrections) >= 8:
                self.backoff_until = now + 60
                self.corrections = []
                if not self.backoff_logged:
                    log('too many corrections in 30s; backing off 60s '
                        '(another agent may be fighting this service)')
                    self.backoff_logged = True
                return

            params = GLib.Variant('(uua(iiduba(ssa{sv}))a{sv})',
                                  (st['serial'], 1, variants,
                                   {'layout_mode': GLib.Variant('u', int(st['layout_mode']))}))
            self.bus.call_sync(DC, PATH, DC, 'ApplyMonitorsConfig', params, None,
                               Gio.DBusCallFlags.NONE, -1, None)
            log(f'corrected ({reason}): ' + '; '.join(changes))
            self.sync_monitors_xml(applied, st['conn_info'], st['mode_dims'])
        except GLib.Error as e:
            log(f'correction ({reason}) failed: {e.message}')
        except Exception as e:  # noqa: BLE001
            log(f'correction ({reason}) error: {e!r}')

    # ---------- events ----------

    def on_changed(self, connection, sender, path, iface, signal, user_data):
        cfg = read_config()
        try:
            debounce = int(cfg.get('debounce-ms', '600'))
        except ValueError:
            debounce = 600
        if self.debounce_id is not None:
            GLib.source_remove(self.debounce_id)
        self.debounce_id = GLib.timeout_add(
            debounce, lambda: (self.correct('monitors-changed'), False)[1])


def main():
    log('fixed-display-scale watcher starting')
    ensure_fractional_scaling()
    w = Watcher()
    w.bus.signal_subscribe(DC, DC, 'MonitorsChanged', PATH, None,
                           Gio.DBusSignalFlags.NONE, w.on_changed)
    GLib.timeout_add(3000, lambda: (w.correct('startup'), False)[1])
    GLib.timeout_add_seconds(10, lambda: (w.correct('periodic'), True)[1])
    GLib.MainLoop().run()


if __name__ == '__main__':
    main()
