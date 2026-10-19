"""Render OmniWM workspaces in SketchyBar; follow IPC events and reconnect."""
import datetime
import json
from pathlib import Path
import re
import subprocess
import sys
import psutil
import fcntl
import os

BAR, ACTION = sys.argv[1:3]
OMNI = str(Path.home() / '.nix-profile/bin/omniwmctl')


def bar(*args):
    subprocess.run([BAR, *args], check=True, timeout=5)


def update():
    # Serialize launchd events and the recovery timer during reloads.
    with open(f'/tmp/omniwm-sketchybar-{os.getuid()}.lock', 'w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        update_workspaces()


def update_workspaces():
    reply = subprocess.run(
        [OMNI, 'query', 'workspaces', '--json'],
        capture_output=True, text=True, check=True, timeout=5,
    )
    data = json.loads(reply.stdout)
    if not data.get('ok'):
        raise RuntimeError('OmniWM workspace query failed')
    args = []
    for ws in data['result']['payload']['workspaces']:
        name = ws['rawName']
        if name not in {str(n) for n in range(1, 10)}:
            continue
        active = ws.get('isFocused', False)
        occupied = ws.get('counts', {}).get('total', 0) > 0
        args += ['--set', f'workspace.{name}',
                 f'background.color={"0xffeed49f" if active else "0x00000000"}',
                 f'background.drawing={"on" if active else "off"}',
                 f'label.color={"0xff181926" if active else "0xffcad3f5" if occupied else "0xff8087a2"}']
    if args:
        bar(*args)


if ACTION == 'clock':
    bar('--set', 'clock', 'label=' + datetime.datetime.now().strftime('%H:%M'))
elif ACTION == 'date':
    today = datetime.datetime.now()
    weekdays = ['mån', 'tis', 'ons', 'tor', 'fre', 'lör', 'sön']
    months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec']
    bar('--set', 'date', f'label={today:%d} {months[today.month - 1]} {weekdays[today.weekday()]}')
elif ACTION == 'cpu':
    bar('--set', 'cpu', f'label={psutil.cpu_percent(interval=0.2):.0f}%')
elif ACTION == 'memory':
    memory = psutil.virtual_memory()
    used = (memory.total - memory.available) / 1024 ** 3
    # macOS pressure is more useful than allocation percentage: cached RAM
    # can be reclaimed without putting the system under memory pressure.
    pressure = subprocess.check_output(
        ['/usr/sbin/sysctl', '-n', 'kern.memorystatus_vm_pressure_level'],
        text=True, timeout=5,
    ).strip()
    status, color = {
        '1': ('Normal', '0xffa6da95'),
        '2': ('Varning', '0xffeed49f'),
        '4': ('Kritiskt', '0xffed8796'),
    }.get(pressure, ('Okänt', '0xff8087a2'))
    bar('--set', 'memory', f'label={status} | {used:.1f}G',
        'icon.color=' + color)
elif ACTION == 'battery':
    output = subprocess.check_output(['/usr/bin/pmset', '-g', 'batt'], text=True, timeout=5)
    percent = re.search(r'(\d+)%', output)
    label = (percent.group() if percent else '—')
    level = int(percent.group(1)) if percent else 0
    charging = 'AC Power' in output
    icon = '' if charging else ['', '', '', '', ''][min(level // 25, 4)]
    color = '0xffeed49f' if charging else '0xffed8796' if level < 20 else '0xff91d7e3'
    bar('--set', 'battery', 'label=' + label, 'icon=' + icon, 'icon.color=' + color)
elif ACTION == 'wifi':
    ports = subprocess.check_output(['/usr/sbin/networksetup', '-listallhardwareports'], text=True, timeout=5)
    match = re.search(r'Hardware Port: (?:Wi-Fi|AirPort)\nDevice: (\S+)', ports)
    powered = connected = False
    if match:
        device = match.group(1)
        power = subprocess.check_output(['/usr/sbin/networksetup', '-getairportpower', device], text=True, timeout=5)
        powered = ': On' in power
        connected = subprocess.run(['/usr/sbin/ipconfig', 'getifaddr', device], capture_output=True, timeout=5).returncode == 0
    # Icon only: sky when connected, dim when idle, struck through when off.
    bar('--set', 'wifi', 'icon=' + ('\U000f05a9' if powered else '\U000f05aa'),
        'icon.color=' + ('0xff91d7e3' if connected else '0xff8087a2'))
elif ACTION == 'bluetooth':
    report = json.loads(subprocess.check_output(
        ['/usr/sbin/system_profiler', 'SPBluetoothDataType', '-json'], text=True, timeout=15,
    )).get('SPBluetoothDataType', [{}])[0]
    state = report.get('controller_properties', {}).get('controller_state')
    connected = sum(len(group) for group in report.get('device_connected', []))
    # Show the device count only when something is connected.
    bar('--set', 'bluetooth', f'label={connected}',
        'label.drawing=' + ('on' if connected else 'off'),
        'icon.padding_right=' + ('3' if connected else '10'),
        'icon=' + ('\U000f00b2' if state == 'attrib_off' else '\U000f00af'),
        'icon.color=' + ('0xff91d7e3' if state == 'attrib_on' else '0xff8087a2'))
elif ACTION == 'update':
    update()
elif ACTION == 'watch':
    stream = subprocess.Popen(
        [OMNI, 'subscribe', 'active-workspace,windows-changed,display-changed',
         '--reconnect', '--format', 'ndjson'], stdout=subprocess.PIPE, text=True,
    )
    try:
        for line in stream.stdout:
            try:
                update()
            except (subprocess.SubprocessError, ValueError, KeyError, RuntimeError) as error:
                print(error, file=sys.stderr, flush=True)
    finally:
        stream.terminate()
        stream.wait()
    sys.exit('OmniWM subscription ended')
