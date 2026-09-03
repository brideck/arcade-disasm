#!/usr/bin/env python3
"""
validate_inline_addrs.py — Check that inline address DB pairs in an .asm file
still match their intended label targets after a build.

Some addresses are encoded as raw DB bytes (hi byte first) rather than
assembler-visible labels — e.g. message pointers and inline jump targets.
These cannot be expressed as assembler labels and must be verified after
any build that might shift their targets.

Mark a DB pair in the .asm with an @addr annotation in its comment:

    DB $00, $2B    ; @addr MSG_COMPUTER_OTHELLO "COMPUTER OTHELLO"
    DB $01, $BD    ; @addr CLEAR_AND_PROMPT_FOR_JUDGE

The tool reads (b0 << 8) | b1 as the encoded address and compares it
to the assembled address of the named label.

Usage:
    python3 tools/validate_inline_addrs.py <list_file> <asm_file>

The list file is produced by z80asm --list during assemble.sh.

Exit code 0 if all addresses match, 1 if any have drifted.
"""

import re
import sys

ANNOTATION = re.compile(r'@addr\s+([A-Z][A-Z0-9_]+)', re.IGNORECASE)
ORG_CHECK  = re.compile(r'@org\s+\$([0-9A-Fa-f]{4})', re.IGNORECASE)
DB_PAIR    = re.compile(r'DB\s+\$([0-9A-Fa-f]{2})\s*,\s*\$([0-9A-Fa-f]{2})')
LIST_LABEL = re.compile(r'^([0-9a-f]{4})\s+([A-Z][A-Z0-9_]+):\s*$', re.IGNORECASE)
LIST_INSTR = re.compile(r'^([0-9a-f]{4})\s+[0-9a-f]{2}', re.IGNORECASE)


def load_label_map(list_path):
    """Returns (label_map, addr_set) where addr_set is the set of all
    assembled addresses that have at least one instruction byte."""
    label_map = {}
    addr_set = set()
    with open(list_path) as f:
        for line in f:
            lm = LIST_LABEL.match(line)
            if lm:
                label = lm.group(2).upper()
                if label not in label_map:
                    label_map[label] = int(lm.group(1), 16)
            im = LIST_INSTR.match(line)
            if im:
                addr_set.add(int(im.group(1), 16))
    return label_map, addr_set


def main():
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} <list_file> <asm_file>', file=sys.stderr)
        sys.exit(1)

    list_path, asm_path = sys.argv[1], sys.argv[2]

    label_map, addr_set = load_label_map(list_path)

    errors = checked = 0
    with open(asm_path) as f:
        for lineno, line in enumerate(f, 1):
            # --- @addr check: DB $HI, $LO encodes a label address ---
            ann = ANNOTATION.search(line)
            if ann:
                label = ann.group(1).upper()
                db = DB_PAIR.search(line)
                if not db:
                    print(f'WARNING line {lineno}: @addr annotation but no DB $XX, $XX found')
                    continue
                b0 = int(db.group(1), 16)
                b1 = int(db.group(2), 16)
                actual = (b0 << 8) | b1
                if label not in label_map:
                    print(f'WARNING line {lineno}: label {label!r} not found in list file')
                    continue
                expected = label_map[label]
                checked += 1
                if actual == expected:
                    print(f'OK     line {lineno:4d}: DB ${b0:02X}, ${b1:02X} = ${actual:04X} = {label}')
                else:
                    print(f'DRIFT  line {lineno:4d}: DB ${b0:02X}, ${b1:02X} = ${actual:04X}'
                          f'  but {label} is now at ${expected:04X}  *** UPDATE NEEDED ***')
                    errors += 1

            # --- @org check: this instruction must assemble at a fixed address ---
            org = ORG_CHECK.search(line)
            if org:
                required = int(org.group(1), 16)
                instr = line.strip()
                if ';' in instr:
                    instr = instr[:instr.index(';')].strip()
                checked += 1
                # We can't match source text directly (preprocessor renames mnemonics),
                # so we verify the required address exists as an instruction boundary.
                # If code above has grown/shrunk, the instruction will have moved and
                # the required address will either be absent or mid-instruction.
                if required in addr_set:
                    print(f'OK     line {lineno:4d}: {instr} — ${required:04X} is a valid instruction address')
                else:
                    # Find the nearest instruction address to show the offset
                    nearest = min(addr_set, key=lambda a: abs(a - required))
                    delta = nearest - required
                    delta_str = f'+{delta}' if delta > 0 else str(delta)
                    print(f'DRIFT  line {lineno:4d}: {instr} — landed at ${nearest:04X} ({delta_str} bytes from required ${required:04X})  *** CHECK NEEDED ***')
                    errors += 1

    if checked == 0:
        print('No @addr annotations found.')
        sys.exit(0)

    if errors:
        print(f'\n{errors}/{checked} address(es) have drifted — update the DB bytes in the source.')
        sys.exit(1)
    else:
        print(f'\nAll {checked} inline addresses match.')


if __name__ == '__main__':
    main()
