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

SOURCE="${1:-$REPO_ROOT/ComputerOthello/cothello-disasm.asm}"
OUTDIR="${2:-$REPO_ROOT/ComputerOthello/rom}"

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
mkdir -p "$OUTDIR"

# --- Step 1: Preprocess (8080 → Z80 mnemonics) ---
echo "==> Preprocessing..."
python3 "$PREPROCESS" "$SOURCE" "$Z80_ASM"

# --- Step 2: Assemble ---
echo "==> Assembling with z80asm..."
z80asm --list="$LIST_FILE" -o "$FLAT_BIN" "$Z80_ASM"
ACTUAL=$(wc -c < "$FLAT_BIN")
echo "    Output: $ACTUAL bytes"
if [ "$ACTUAL" -ne 3072 ]; then
    echo "ERROR: Expected 3072 bytes (3x 1K chips), got $ACTUAL" >&2
    exit 1
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
