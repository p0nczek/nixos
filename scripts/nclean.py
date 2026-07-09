#!/usr/bin/env python3
"""nix-sweeper: curses TUI for managing NixOS generations."""

import curses
import re
import subprocess
import sys
import time
from dataclasses import dataclass


# ═══════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════


@dataclass
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
    generations = []
    lines = output.strip().split("\n")

    header_idx = None
    for i, line in enumerate(lines):
        if "Generation" in line and "Build Date" in line:
            header_idx = i
            break
    if header_idx is None:
        return generations

    for line in lines[header_idx + 1 :]:
        line = line.strip()
        if not line:
            continue
        m = re.match(
            r"(\d+)\s+(\(current\)\s+)?"
            r"(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+"
            r"(\S+)\s+(\S+)\s+(.+)",
            line,
        )
        if m:
            generations.append(Generation(
                number=int(m.group(1)),
                is_current=bool(m.group(2)),
                build_date=m.group(3),
                nixos_version=m.group(4),
                kernel=m.group(5),
                closure_size=m.group(6).strip(),
            ))
    return generations


def fetch_generations() -> list[Generation]:
    """Run `nh os info` and return parsed generations."""
    try:
        r = subprocess.run(["nh", "os", "info"], capture_output=True, text=True, timeout=30)
        return parse_nh_output(r.stdout)
    except (subprocess.SubprocessError, FileNotFoundError):
        return []


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


def draw_summary(scr, y, gens, gc_on, w):
    total = len(gens)
    marked = sum(1 for g in gens if g.marked)
    line = f" ═ NixOS Generations ({total} total"
    if marked:
        line += f", {marked} marked"
    line += ")"
    safe_addstr(scr, y, 0, line, curses.color_pair(C_CYAN) | curses.A_BOLD)

    gc_str = f"GC:{'on' if gc_on else 'off'}"
    c = C_GREEN if gc_on else C_RED
    safe_addstr(scr, y, w - len(gc_str) - 2, gc_str,
                curses.color_pair(c) | curses.A_BOLD)


def draw_table_header(scr, y, w):
    hdr = "       Gen#   Build Date           Version              Kernel    Size"
    safe_addstr(scr, y, 0, hdr, curses.color_pair(C_WHITE) | curses.A_BOLD)


def draw_row(scr, y, gen: Generation, is_cursor: bool, w):
    if gen.is_current:
        marker = "[★]"
    elif gen.marked:
        marker = "[x]"
    else:
        marker = "[ ]"

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
    stdscr.nodelay(True)
    stdscr.timeout(1000)

    gens: list[Generation] = []
    cursor = 0
    scroll = 0
    gc_on = True
    confirming = False
    last_refresh = 0.0
    status_msg = ""
    status_time = 0.0

    while True:
        now = time.time()
        key = stdscr.getch()

        # ── Auto-refresh ─────────────────────────────────
        if now - last_refresh >= 30 or not gens:
            gens = fetch_generations()
            last_refresh = now
            cursor = min(cursor, max(0, len(gens) - 1))

        # ── Key handling ─────────────────────────────────
        if confirming:
            if key in (ord("y"), ord("Y")):
                confirming = False
                to_del = [g.number for g in gens if g.marked]
                if to_del:
                    ok = run_delete(stdscr, to_del, gc_on)
                    gens = fetch_generations()
                    last_refresh = now
                    cursor = min(cursor, max(0, len(gens) - 1))
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
                    g.marked = not g.marked
            elif key in (ord("a"), ord("A")) and gens:
                for g in gens[cursor:]:
                    if not g.is_current:
                        g.marked = True
            elif key in (ord("u"), ord("U")):
                for g in gens:
                    g.marked = False
            elif key in (ord("d"), ord("D")):
                cnt = sum(1 for g in gens if g.marked)
                if cnt == 0:
                    status_msg = "Nothing marked"
                    status_time = now
                else:
                    confirming = True
            elif key in (ord("g"), ord("G")):
                gc_on = not gc_on
                status_msg = f"GC {'on' if gc_on else 'off'}"
                status_time = now
            elif key in (ord("r"), ord("R")):
                gens = fetch_generations()
                last_refresh = now
                cursor = min(cursor, max(0, len(gens) - 1))
                status_msg = "Refreshed"
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
        draw_summary(stdscr, y, gens, gc_on, w)
        y += 2

        if not gens:
            safe_addstr(stdscr, y, 2, "No generations found. Is `nh` installed?",
                        curses.color_pair(C_RED))
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
            draw_confirm(stdscr, sum(1 for g in gens if g.marked), h, w)
        else:
            draw_help(stdscr, h, w)

        stdscr.refresh()


# ═══════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    curses.wrapper(main)
