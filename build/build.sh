#!/bin/bash

MODE=${1:-"build"}

P='\033[38;2;48;255;106m'
D='\033[38;2;255;210;50m'
B='\033[38;2;50;231;255m'
E='\033[38;2;255;74;50m'
R='\033[0m'

{
    echo "-- Generated from package.json | build/build.sh"
    echo ""
    echo "return [["
    cat package.json
    echo "]]"
} > build/package.lua

if [ "$MODE" = "dev" ]; then
    INPUT=${2:-"./main.client.lua"}
    CONFIG="build/darklua.dev.config.json"
    PREFIX="${D}[ DEV ]${R}"
else
    INPUT="src/Init.lua"
    CONFIG="build/darklua.config.json"
    PREFIX="${B}[ BUILD ]${R}"
fi

OUTPUT="dist/main.lua"

PKG=$(node -e "const p=require('./package.json');console.log(JSON.stringify({v:p.version||'',d:p.description||'',r:p.repository||'',s:p.discord||'',l:p.license||''}))")

[ $? -ne 0 ] && echo -e "${E}[ × ]${R} Failed to read package.json" && exit 1

VER=$(echo $PKG | node -pe "JSON.parse(require('fs').readFileSync(0,'utf-8')).v")
DATE=$(date '+%Y-%m-%d')

HEADER=$(cat build/header.lua | node -e "
const pkg=JSON.parse('$PKG');
let h=require('fs').readFileSync(0,'utf-8');
h=h.replace(/{{VERSION}}/g,'$VER')
   .replace(/{{BUILD_DATE}}/g,'$DATE')
   .replace(/{{DESCRIPTION}}/g,pkg.d)
   .replace(/{{REPOSITORY}}/g,pkg.r)
   .replace(/{{DISCORD}}/g,pkg.s)
   .replace(/{{LICENSE}}/g,pkg.l);
console.log(h);
")

START=$(date +%s%N)
DARKLUA_OUT=$(darklua process "$INPUT" dist/temp.lua --config "$CONFIG" 2>&1)
DARKLUA_EXIT=$?

if [ $DARKLUA_EXIT -ne 0 ]; then
    echo -e "${E}[ × ]${R} DarkLua failed"
    echo "$DARKLUA_OUT"
    rm -f dist/temp.lua
    exit 1
fi

END=$(date +%s%N)
TIME=$((($END - $START) / 1000000))

echo "$HEADER" > "$OUTPUT"
echo "" >> "$OUTPUT"
cat dist/temp.lua >> "$OUTPUT"
rm -f dist/temp.lua

SIZE=$(($(wc -c < "$OUTPUT") / 1024))

echo ""
echo -e "[ $(date '+%H:%M:%S') ]"
echo -e "${P}[ ✓ ]${R} $PREFIX"
echo -e "${P}[ > ]${R} CodexUI Build completed successfully"
echo -e "${P}[ > ]${R} Version: ${VER}"
echo -e "${P}[ > ]${R} Time taken: ${TIME}ms"
echo -e "${P}[ > ]${R} Size: ${SIZE}KB"
echo -e "${P}[ > ]${R} Output file: ${OUTPUT}"
echo ""
