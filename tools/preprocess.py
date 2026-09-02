#!/usr/bin/env python3
"""
preprocess.py — Translate Intel 8080 assembly mnemonics to Z80 equivalents.

The Z80 instruction set is a strict superset of the 8080. Every 8080 opcode
has the same binary encoding in Z80; only the mnemonic names differ. This
script performs pure text substitution so that z80asm can assemble 8080 source.

Usage:
    python3 tools/preprocess.py input.asm output_z80.asm
"""

import re
import sys

# ---------------------------------------------------------------------------
# Each entry maps an 8080 mnemonic (with operand pattern) to a Z80 equivalent.
#
# Rules are matched against the INSTRUCTION PORTION of a line only
# (after stripping the leading whitespace and before any comment).
# Each line is matched against rules in order; the FIRST match wins and
# no further rules are applied. This prevents double-translation.
#
# Key 8080 → Z80 differences handled here:
#   - Register 'M' (memory at HL) → '(HL)'
#   - Register pair names B/D/H → BC/DE/HL
#   - PSW → AF
#   - Mnemonic renames (LXI→LD, MVI→LD, STA→LD, etc.)
# ---------------------------------------------------------------------------

# Each rule: (compiled_regex_matching_full_instruction, replacement_string)
# The regex must match the entire instruction text (mnemonic + operands),
# and is applied to the instruction portion only (no leading whitespace, no comment).

_RAW_RULES = [
    # --- Load/Store ---
    (r'LXI\s+SP\s*,\s*(\S+)',   r'LD SP, \1'),
    (r'LXI\s+B\s*,\s*(\S+)',    r'LD BC, \1'),
    (r'LXI\s+D\s*,\s*(\S+)',    r'LD DE, \1'),
    (r'LXI\s+H\s*,\s*(\S+)',    r'LD HL, \1'),
    (r'MVI\s+M\s*,\s*(\S+)',    r'LD (HL), \1'),
    (r'MVI\s+(A|B|C|D|E|H|L)\s*,\s*(\S+)', r'LD \1, \2'),
    (r'STA\s+(\S+)',             r'LD (\1), A'),
    (r'LDA\s+(\S+)',             r'LD A, (\1)'),
    (r'STAX\s+B',                r'LD (BC), A'),
    (r'STAX\s+D',                r'LD (DE), A'),
    (r'LDAX\s+B',                r'LD A, (BC)'),
    (r'LDAX\s+D',                r'LD A, (DE)'),
    (r'SHLD\s+(\S+)',            r'LD (\1), HL'),
    (r'LHLD\s+(\S+)',            r'LD HL, (\1)'),
    (r'MOV\s+M\s*,\s*(A|B|C|D|E|H|L)',  r'LD (HL), \1'),
    (r'MOV\s+(A|B|C|D|E|H|L)\s*,\s*M', r'LD \1, (HL)'),
    (r'MOV\s+(A|B|C|D|E|H|L)\s*,\s*(A|B|C|D|E|H|L)', r'LD \1, \2'),
    (r'SPHL',                    r'LD SP, HL'),

    # --- Stack ---
    (r'PUSH\s+PSW',  r'PUSH AF'),
    (r'POP\s+PSW',   r'POP AF'),
    (r'PUSH\s+B',    r'PUSH BC'),
    (r'PUSH\s+D',    r'PUSH DE'),
    (r'PUSH\s+H',    r'PUSH HL'),
    (r'POP\s+B',     r'POP BC'),
    (r'POP\s+D',     r'POP DE'),
    (r'POP\s+H',     r'POP HL'),
    (r'XTHL',        r'EX (SP), HL'),
    (r'XCHG',        r'EX DE, HL'),

    # --- Arithmetic ---
    (r'ADI\s+(\S+)',  r'ADD A, \1'),
    (r'ACI\s+(\S+)',  r'ADC A, \1'),
    (r'SUI\s+(\S+)',  r'SUB \1'),
    (r'SBI\s+(\S+)',  r'SBC A, \1'),
    (r'ADD\s+M',      r'ADD A, (HL)'),
    (r'ADD\s+(A|B|C|D|E|H|L)', r'ADD A, \1'),
    (r'ADC\s+M',      r'ADC A, (HL)'),
    (r'ADC\s+(A|B|C|D|E|H|L)', r'ADC A, \1'),
    (r'SUB\s+M',      r'SUB (HL)'),
    (r'SBB\s+M',      r'SBC A, (HL)'),
    (r'SBB\s+(A|B|C|D|E|H|L)', r'SBC A, \1'),
    (r'DAD\s+B',      r'ADD HL, BC'),
    (r'DAD\s+D',      r'ADD HL, DE'),
    (r'DAD\s+H',      r'ADD HL, HL'),
    (r'DAD\s+SP',     r'ADD HL, SP'),
    (r'INR\s+M',      r'INC (HL)'),
    (r'INR\s+(A|B|C|D|E|H|L)', r'INC \1'),
    (r'DCR\s+M',      r'DEC (HL)'),
    (r'DCR\s+(A|B|C|D|E|H|L)', r'DEC \1'),
    (r'INX\s+B',      r'INC BC'),
    (r'INX\s+D',      r'INC DE'),
    (r'INX\s+H',      r'INC HL'),
    (r'INX\s+SP',     r'INC SP'),
    (r'DCX\s+B',      r'DEC BC'),
    (r'DCX\s+D',      r'DEC DE'),
    (r'DCX\s+H',      r'DEC HL'),
    (r'DCX\s+SP',     r'DEC SP'),

    # --- Logical ---
    (r'ANI\s+(\S+)',  r'AND \1'),
    (r'XRI\s+(\S+)',  r'XOR \1'),
    (r'ORI\s+(\S+)',  r'OR \1'),
    (r'CPI\s+(\S+)',  r'CP \1'),
    (r'ANA\s+M',      r'AND (HL)'),
    (r'ANA\s+(A|B|C|D|E|H|L)', r'AND \1'),
    (r'XRA\s+M',      r'XOR (HL)'),
    (r'XRA\s+(A|B|C|D|E|H|L)', r'XOR \1'),
    (r'ORA\s+M',      r'OR (HL)'),
    (r'ORA\s+(A|B|C|D|E|H|L)', r'OR \1'),
    (r'CMP\s+M',      r'CP (HL)'),
    (r'CMP\s+(A|B|C|D|E|H|L)', r'CP \1'),
    (r'CMA',          r'CPL'),

    # --- Jumps ---
    (r'JMP\s+(\S+)',  r'JP \1'),
    (r'JZ\s+(\S+)',   r'JP Z, \1'),
    (r'JNZ\s+(\S+)',  r'JP NZ, \1'),
    (r'JC\s+(\S+)',   r'JP C, \1'),
    (r'JNC\s+(\S+)',  r'JP NC, \1'),
    (r'JM\s+(\S+)',   r'JP M, \1'),
    (r'JP\s+(\S+)',   r'JP P, \1'),
    (r'JPE\s+(\S+)',  r'JP PE, \1'),
    (r'JPO\s+(\S+)',  r'JP PO, \1'),
    (r'PCHL',         r'JP (HL)'),

    # --- Calls ---
    (r'CNZ\s+(\S+)',  r'CALL NZ, \1'),
    (r'CZ\s+(\S+)',   r'CALL Z, \1'),
    (r'CNC\s+(\S+)',  r'CALL NC, \1'),
    (r'CC\s+(\S+)',   r'CALL C, \1'),
    (r'CM\s+(\S+)',   r'CALL M, \1'),
    (r'CPO\s+(\S+)',  r'CALL PO, \1'),
    (r'CPE\s+(\S+)',  r'CALL PE, \1'),
    (r'CP\s+(\S+)',   r'CALL P, \1'),

    # --- Returns ---
    (r'RNZ',  r'RET NZ'),
    (r'RZ',   r'RET Z'),
    (r'RNC',  r'RET NC'),
    (r'RC',   r'RET C'),
    (r'RM',   r'RET M'),
    (r'RP',   r'RET P'),
    (r'RPE',  r'RET PE'),
    (r'RPO',  r'RET PO'),

    # --- Rotate ---
    (r'RLC',  r'RLCA'),
    (r'RRC',  r'RRCA'),
    (r'RAL',  r'RLA'),
    (r'RAR',  r'RRA'),

    # --- Misc ---
    (r'STC',  r'SCF'),
    (r'CMC',  r'CCF'),
]

# Compile: anchor each pattern to full-match the instruction text (case-insensitive)
RULES = [(re.compile(r'(?i)^' + pat + r'$'), repl) for pat, repl in _RAW_RULES]

# Instruction line: optional leading whitespace, then the instruction, then optional comment
INSTR_LINE = re.compile(r'^(?P<indent>\s+)(?P<instr>[^;]+?)(?P<comment>\s*(?:;.*)?)$')


def translate_line(line: str) -> str:
    """Translate one line of 8080 assembly to Z80 syntax.

    Matches the instruction text exactly once against the rule list.
    The first matching rule wins; no further rules are applied.
    Comments and indentation are preserved unchanged.
    Non-instruction lines (labels, directives, blanks) pass through unchanged.
    """
    m = INSTR_LINE.match(line.rstrip('\n'))
    if not m:
        return line

    indent = m.group('indent')
    instr = m.group('instr').rstrip()
    comment = m.group('comment')

    for pattern, replacement in RULES:
        translated = pattern.sub(replacement, instr)
        if translated != instr:
            # First match wins — stop here
            return indent + translated + comment + '\n'

    # No rule matched — pass through unchanged (handles CALL, RET, NOP, DB, etc.)
    return line


def main():
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} input.asm output_z80.asm', file=sys.stderr)
        sys.exit(1)

    in_path, out_path = sys.argv[1], sys.argv[2]
    with open(in_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    translated = [translate_line(line) for line in lines]

    with open(out_path, 'w', encoding='utf-8') as f:
        f.writelines(translated)

    print(f'Translated {len(lines)} lines → {out_path}')


if __name__ == '__main__':
    main()
