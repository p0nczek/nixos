#!/usr/bin/env python3
"""nclean: curses TUI for managing NixOS generations."""

from __future__ import annotations

import curses
import re
import subprocess
import threading
import time
from dataclasses import dataclass


# ═══════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════

GEN_RE = re.compile(
    r"(\d+)\s+(\(current\)\s+)?"
    r"(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+"
    r"(\S+)\s+(\S+)\s+(.+)"
)
REFRESH_INTERVAL = 30  # seconds between background refreshes


@dataclass(slots=True)
class Generation:
    number: int
    is_current: bool
    build_date: str
    nixos_version: str
    kernel: str
    closure_size: str
    marked: bool = False


def parse_nh_output(output: str) -> list[Generation]:
    """Parse `nh os info` stdout into a list of Generation objects."""
    lines = output.strip().split("\n")
    header_idx = next(
        (i for i, l in enumerate(lines) if "Generation" in l and "Build Date" in l),
        None,
    )
    if header_idx is None:
        return []

    gens: list[Generation] = []
    for line in lines[header_idx + 1:]:
        line = line.strip()
        if not line:
            continue
        m = GEN_RE.match(line)
        if m:
            gens.append(Generation(
                number=int(m.group(1)),
                is_current=bool(m.group(2)),
                build_date=m.group(3),
                nixos_version=m.group(4),
                kernel=m.group(5),
                closure_size=m.group(6).strip(),
            ))
    return gens


def fetch_generations() -> list[Generation]:
    """Run `nh os info` and return parsed generations (blocking; call off-thread)."""
    try:
        r = subprocess.run(["nh", "os", "info"], capture_output=True, text=True, timeout=30)
        return parse_nh_output(r.stdout)
    except (subprocess.SubprocessError, FileNotFoundError, OSError):
        return []


class Store:
    """Thread-safe holder for the generation list + marks.

    Refresh runs on a background thread so `nh os info` (which can take
    a noticeable moment) never freezes the UI loop.
    """

    def __init__(self):
        self._lock = threading.Lock()
        self._gens: list[Generation] = []
        self._marks: set[int] = set()
        self.loading = True

    def snapshot(self) -> list[Generation]:
        with self._lock:
            for g in self._gens:
                g.marked = g.number in self._marks
            return list(self._gens)

    def refresh_async(self):
        threading.Thread(target=self._refresh, daemon=True).start()

    def _refresh(self):
        gens = fetch_generations()
        with self._lock:
            self._gens = gens
            self._marks &= {g.number for g in gens}  # drop stale marks
            self.loading = False

    def toggle_mark(self, number: int):
        with self._lock:
            self._marks.symmetric_difference_update({number})

    def mark_from(self, numbers: list[int]):
        with self._lock:
            self._marks.update(numbers)

    def clear_marks(self):
        with self._lock:
            self._marks.clear()

    def marked_numbers(self) -> list[int]:
        with self._lock:
            return sorted(self._marks)

    def mark_count(self) -> int:
        with self._lock:
            return len(self._marks)


# ═══════════════════════════════════════════════════════════════════
# SYSTEM COMMANDS (sudo-safe)
# ═══════════════════════════════════════════════════════════════════


def run_delete(stdscr, numbers: list[int], gc: bool) -> bool:
    """Exit curses so sudo can prompt for password, then resume."""
    curses.endwin()

    print(f"\n  Deleting generations: {', '.join(map(str, sorted(numbers)))}")
    print("  You may be prompted for your password.\n")

    result = subprocess.run(
        ["sudo", "nix-env", "-p", "/nix/var/nix/profiles/system",
         "--delete-generations"] + [str(n) for n in numbers],
    )
    ok = result.returncode == 0

    if ok:
        print("\n  ✓ Generations deleted.")
        if gc:
            print("  Running garbage collection...")
            subprocess.run(["sudo", "nix-collect-garbage"])
            print("  ✓ Done.")
    else:
        print(f"\n  ✗ Failed (exit code {result.returncode})")

    input("\n  Press Enter to return...")
    stdscr.refresh()
    return ok


# ═══════════════════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════════════════

C_RED, C_GREEN, C_YELLOW, C_BLUE = 1, 2, 3, 4
C_MAGENTA, C_CYAN, C_WHITE = 5, 6, 7
C_HEADER, C_CURSOR = 8, 9


def setup_colors():
    curses.start_color()
    try:
        curses.use_default_colors()
        bg = -1
    except curses.error:
        bg = curses.COLOR_BLACK
    pairs = [
        (C_RED, curses.COLOR_RED), (C_GREEN, curses.COLOR_GREEN),
        (C_YELLOW, curses.COLOR_YELLOW), (C_BLUE, curses.COLOR_BLUE),
        (C_MAGENTA, curses.COLOR_MAGENTA), (C_CYAN, curses.COLOR_CYAN),
        (C_WHITE, curses.COLOR_WHITE),
    ]
    for pair_id, fg in pairs:
        curses.init_pair(pair_id, fg, bg)
    curses.init_pair(C_HEADER, curses.COLOR_BLACK, curses.COLOR_WHITE)
    curses.init_pair(C_CURSOR, curses.COLOR_BLACK, curses.COLOR_CYAN)


# ═══════════════════════════════════════════════════════════════════
# DRAWING HELPERS
# ═══════════════════════════════════════════════════════════════════


def safe_addstr(scr, y, x, text, attr=0):
    """addstr that clips to screen and ignores edge errors."""
    h, w = scr.getmaxyx()
    if y < 0 or y >= h or x >= w:
        return
    try:
        scr.addstr(y, x, text[: max(0, w - x - 1)], attr)
    except curses.error:
        pass


def draw_header(scr, w):
    title = " nix-sweeper "
    now = time.strftime("%H:%M:%S")
    scr.addstr(0, 0, " " * (w - 1), curses.color_pair(C_HEADER))
    safe_addstr(scr, 0, max(0, (w - len(title)) // 2), title,
                curses.color_pair(C_HEADER) | curses.A_BOLD)
    safe_addstr(scr, 0, w - len(now) - 2, now, curses.color_pair(C_HEADER))


def draw_sep(scr, y, w):
    safe_addstr(scr, y, 0, "─" * (w - 1), curses.color_pair(C_WHITE))


def draw_summary(scr, y, gens, marked, loading, gc_on, w):
    total = len(gens)
    line = f" ═ NixOS Generations ({total} total"
    if marked:
        line += f", {marked} marked"
    line += ")"
    if loading:
        line += "  [refreshing…]"
    safe_addstr(scr, y, 0, line, curses.color_pair(C_CYAN) | curses.A_BOLD)

    gc_str = f"GC:{'on' if gc_on else 'off'}"
    c = C_GREEN if gc_on else C_RED
    safe_addstr(scr, y, w - len(gc_str) - 2, gc_str,
                curses.color_pair(c) | curses.A_BOLD)


def draw_table_header(scr, y, w):
    hdr = "       Gen#   Build Date           Version              Kernel    Size"
    safe_addstr(scr, y, 0, hdr, curses.color_pair(C_WHITE) | curses.A_BOLD)


def draw_row(scr, y, gen: Generation, is_cursor: bool, w):
    marker = "[★]" if gen.is_current else "[x]" if gen.marked else "[ ]"
    prefix = " ▸ " if is_cursor else "   "
    line = (
        f"{prefix}{marker} {gen.number:<6}"
        f" {gen.build_date}  "
        f"{gen.nixos_version:<20.20} "
        f"{gen.kernel:<9} "
        f"{gen.closure_size}"
    )

    if is_cursor:
        attr = curses.color_pair(C_CURSOR) | curses.A_BOLD
        safe_addstr(scr, y, 0, " " * (w - 1), attr)
        safe_addstr(scr, y, 0, line, attr)
    elif gen.is_current:
        safe_addstr(scr, y, 0, line, curses.color_pair(C_GREEN) | curses.A_BOLD)
    elif gen.marked:
        safe_addstr(scr, y, 0, line, curses.color_pair(C_RED) | curses.A_BOLD)
    else:
        safe_addstr(scr, y, 0, line, curses.color_pair(C_WHITE))


def draw_help(scr, h, w):
    txt = " q:exit  Space:toggle  a:mark-below  u:unmark-all  d:delete  g:gc  r:refresh"
    safe_addstr(scr, h - 1, 0, txt, curses.color_pair(C_WHITE))


def draw_confirm(scr, count, h, w):
    msg = f" Delete {count} generation(s)? [y/N] "
    safe_addstr(scr, h - 1, 0, " " * (w - 1),
                curses.color_pair(C_RED) | curses.A_BOLD)
    safe_addstr(scr, h - 1, max(0, (w - len(msg)) // 2), msg,
                curses.color_pair(C_RED) | curses.A_BOLD)


# ═══════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════════


def main(stdscr):
    setup_colors()
    curses.curs_set(0)
    stdscr.timeout(200)  # ms: responsive keys, periodic redraw for clock/spinner

    store = Store()
    store.refresh_async()

    gens: list[Generation] = []
    cursor = 0
    scroll = 0
    gc_on = True
    confirming = False
    last_refresh = time.time()
    status_msg = ""
    status_time = 0.0

    while True:
        now = time.time()
        key = stdscr.getch()

        if not store.loading:
            gens = store.snapshot()
            cursor = min(cursor, max(0, len(gens) - 1))

        if now - last_refresh >= REFRESH_INTERVAL:
            store.refresh_async()
            last_refresh = now

        # ── Key handling ─────────────────────────────────
        if confirming:
            if key in (ord("y"), ord("Y")):
                confirming = False
                to_del = store.marked_numbers()
                if to_del:
                    ok = run_delete(stdscr, to_del, gc_on)
                    store.refresh_async()
                    last_refresh = now
                    status_msg = "✓ Deleted" if ok else "✗ Failed"
                    status_time = now
            elif key != -1:
                confirming = False
        else:
            if key in (ord("q"), 27):
                break
            elif key == curses.KEY_DOWN and gens:
                cursor = min(cursor + 1, len(gens) - 1)
            elif key == curses.KEY_UP and gens:
                cursor = max(cursor - 1, 0)
            elif key == ord(" ") and gens:
                g = gens[cursor]
                if g.is_current:
                    status_msg = "Cannot mark current generation"
                    status_time = now
                else:
                    store.toggle_mark(g.number)
            elif key in (ord("a"), ord("A")) and gens:
                store.mark_from([g.number for g in gens[cursor:] if not g.is_current])
            elif key in (ord("u"), ord("U")):
                store.clear_marks()
            elif key in (ord("d"), ord("D")):
                if store.mark_count() == 0:
                    status_msg = "Nothing marked"
                    status_time = now
                else:
                    confirming = True
            elif key in (ord("g"), ord("G")):
                gc_on = not gc_on
                status_msg = f"GC {'on' if gc_on else 'off'}"
                status_time = now
            elif key in (ord("r"), ord("R")):
                store.refresh_async()
                last_refresh = now
                status_msg = "Refreshing…"
                status_time = now

        # ── Drawing ──────────────────────────────────────
        stdscr.erase()
        h, w = stdscr.getmaxyx()
        if h < 6 or w < 40:
            safe_addstr(stdscr, 0, 0, "Terminal too small", curses.A_BOLD)
            stdscr.refresh()
            continue

        draw_header(stdscr, w)
        draw_sep(stdscr, 1, w)

        y = 2
        draw_summary(stdscr, y, gens, store.mark_count(), store.loading, gc_on, w)
        y += 2

        if not gens:
            msg = "Loading…" if store.loading else "No generations found. Is `nh` installed?"
            safe_addstr(stdscr, y, 2, msg, curses.color_pair(C_RED))
        else:
            draw_table_header(stdscr, y, w)
            y += 1
            draw_sep(stdscr, y, w)
            y += 1

            visible = max(1, h - y - 3)
            if cursor < scroll:
                scroll = cursor
            if cursor >= scroll + visible:
                scroll = cursor - visible + 1
            scroll = max(0, scroll)

            for i in range(scroll, min(len(gens), scroll + visible)):
                draw_row(stdscr, y, gens[i], i == cursor, w)
                y += 1

        if status_msg and now - status_time < 3:
            safe_addstr(stdscr, h - 3, 2, status_msg,
                        curses.color_pair(C_YELLOW) | curses.A_BOLD)

        draw_sep(stdscr, h - 2, w)

        if confirming:
            draw_confirm(stdscr, store.mark_count(), h, w)
        else:
            draw_help(stdscr, h, w)

        stdscr.refresh()


# ═══════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    curses.wrapper(main)
