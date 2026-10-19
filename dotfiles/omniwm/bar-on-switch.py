"""Flash OmniWM's bar on focus/workspace changes (single display only).

Uses only Python's standard library and omniwmctl. launchd restarts this process
when OmniWM quits or is not running yet. No settings files are changed here.
"""

import asyncio
import json
import signal
import sys


async def call(cli, *args):
    process = await asyncio.create_subprocess_exec(
        cli, *args, "--json", stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
    )
    try:
        output, _ = await asyncio.wait_for(process.communicate(), 3)
    except BaseException:
        process.kill()
        await process.wait()
        raise
    reply = json.loads(output)
    if process.returncode or not reply.get("ok"):
        raise RuntimeError("OmniWM rejected the bar request (possibly Overview)")
    return reply.get("result", {}).get("payload", {})


async def visible(cli, want):
    monitors = (await call(cli, "query", "workspace-bar"))["monitors"]
    # The toggle command cannot target another display without moving focus.
    if len(monitors) != 1:
        raise RuntimeError("Bar flash requires one display; leaving visibility unchanged")
    monitor = monitors[0]
    if monitor["enabled"] and monitor["isVisible"] != want:
        await call(cli, "command", "toggle-workspace-bar")


def identity(event):
    channel = event.get("channel")
    payload = event.get("result", {}).get("payload", {})
    if channel == "focus":
        return channel, (payload.get("window") or {}).get("id")
    if channel == "active-workspace":
        return channel, (payload.get("workspace") or {}).get("id")
    return None, None


async def run(cli, seconds):
    stream = await asyncio.create_subprocess_exec(
        cli, "subscribe", "focus,active-workspace", "--format", "ndjson",
        stdout=asyncio.subprocess.PIPE,
    )
    reader = None
    try:
        # Subscribe first, then hide; initial snapshots establish the baseline.
        handshake = json.loads(await asyncio.wait_for(stream.stdout.readline(), 5))
        if not handshake.get("ok"):
            raise RuntimeError("OmniWM subscription failed")
        await visible(cli, False)
        previous = {}
        deadline = None
        loop = asyncio.get_running_loop()
        while True:
            if reader is None:
                reader = asyncio.create_task(stream.stdout.readline())
            timeout = None if deadline is None else max(0, deadline - loop.time())
            ready, _ = await asyncio.wait([reader], timeout=timeout)
            if not ready:
                await visible(cli, False)
                deadline = None
                continue
            line = reader.result()
            reader = None
            if not line:
                raise RuntimeError("OmniWM disconnected; waiting for restart")
            channel, current = identity(json.loads(line))
            if channel is None:
                continue
            changed = channel in previous and previous[channel] != current
            previous[channel] = current
            if changed and current is not None:
                await visible(cli, True)
                deadline = loop.time() + seconds
    finally:
        if reader:
            reader.cancel()
            await asyncio.gather(reader, return_exceptions=True)
        if stream.returncode is None:
            stream.terminate()
        await stream.wait()
        # Fail open: a stopped service should leave the normal bar accessible.
        try:
            await visible(cli, True)
        except Exception:
            pass


async def main():
    task = asyncio.create_task(run(sys.argv[1], float(sys.argv[2])))
    for sig in (signal.SIGTERM, signal.SIGINT):
        asyncio.get_running_loop().add_signal_handler(sig, task.cancel)
    try:
        await task
    except asyncio.CancelledError:
        pass


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as error:
        sys.exit(str(error))
