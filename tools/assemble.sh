#!/usr/bin/env bash
# assemble.sh — Build Computer Othello ROM from annotated 8080 assembly source
#
# Pipeline:
#   1. Preprocess: translate 8080 mnemonics → Z80 equivalents (z80asm input)
#   2. Assemble:   z80asm produces a flat 3 KB binary
#   3. Split:      divide binary into three 1 KB chip images
#   4. Package:    zip chip images for MAME
#
# Usage:
#   tools/assemble.sh [source.asm] [output_dir]
#
# Defaults:
#   source:     ComputerOthello/cothello-disasm.asm
#   output_dir: ComputerOthello/rom

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_ARG="${1:-$REPO_ROOT/ComputerOthello/cothello-disasm.asm}"
OUTDIR_ARG="${2:-$REPO_ROOT/ComputerOthello/rom}"

# Normalize SOURCE to absolute path if needed
if [[ "$SOURCE_ARG" = /* ]]; then
    SOURCE="$SOURCE_ARG"
else
    SOURCE="$(cd "$(dirname "$SOURCE_ARG")" && pwd)/$(basename "$SOURCE_ARG")"
fi

# Ensure OUTDIR exists and normalize to absolute path
mkdir -p "$OUTDIR_ARG"
OUTDIR="$(cd "$OUTDIR_ARG" && pwd)"

PREPROCESS="$SCRIPT_DIR/preprocess.py"
VALIDATE="$SCRIPT_DIR/validate_inline_addrs.py"
TMPDIR_Z80="$(mktemp -d)"
Z80_ASM="$TMPDIR_Z80/intermediate.asm"
LIST_FILE="$TMPDIR_Z80/intermediate.lst"
FLAT_BIN="$OUTDIR/cothello-full.bin"
CHIP13="$OUTDIR/13.ic13"
CHIP12="$OUTDIR/12.ic12"
CHIP11="$OUTDIR/11.ic11"
ZIP="$OUTDIR/cothello.zip"

cleanup() { rm -rf "$TMPDIR_Z80"; }
trap cleanup EXIT

echo "==> Source:  $SOURCE"
echo "==> Output:  $OUTDIR"

# --- Step 1: Preprocess (8080 → Z80 mnemonics) ---
echo "==> Preprocessing..."
python3 "$PREPROCESS" "$SOURCE" "$Z80_ASM"

# --- Step 2: Assemble ---
echo "==> Assembling with z80asm..."
z80asm --list="$LIST_FILE" -o "$FLAT_BIN" "$Z80_ASM"
ACTUAL=$(wc -c < "$FLAT_BIN")

if [ "$ACTUAL" -gt 3072 ]; then
    OVER=$((ACTUAL - 3072))
    echo "ERROR: ROM overflow! Output is $ACTUAL bytes (exceeds 3072 by $OVER bytes)" >&2
    exit 1
elif [ "$ACTUAL" -lt 3072 ]; then
    PAD=$((3072 - ACTUAL))
    echo "    Output: $ACTUAL bytes ($PAD bytes free, padding with 0xFF to 3072 bytes)"
    python3 -c "import sys; sys.stdout.buffer.write(b'\xFF' * $PAD)" >> "$FLAT_BIN"
else
    echo "    Output: $ACTUAL bytes (0 bytes free)"
fi

# --- Step 3: Split into chip images ---
echo "==> Splitting into chip images..."
dd if="$FLAT_BIN" of="$CHIP13" bs=1024 count=1 skip=0 2>/dev/null
dd if="$FLAT_BIN" of="$CHIP12" bs=1024 count=1 skip=1 2>/dev/null
dd if="$FLAT_BIN" of="$CHIP11" bs=1024 count=1 skip=2 2>/dev/null
echo "    13.ic13  $(wc -c < "$CHIP13") bytes  (0x0000-0x03FF)"
echo "    12.ic12  $(wc -c < "$CHIP12") bytes  (0x0400-0x07FF)"
echo "    11.ic11  $(wc -c < "$CHIP11") bytes  (0x0800-0x0BFF)"

# --- Step 4: Package for MAME ---
echo "==> Packaging $ZIP..."
(cd "$OUTDIR" && zip -q -j "$ZIP" 13.ic13 12.ic12 11.ic11)
echo "    Done: $ZIP"

# --- Step 5: Validate inline addresses ---
echo "==> Validating inline addresses..."
python3 "$VALIDATE" "$LIST_FILE" "$SOURCE"

echo "==> Build complete."
