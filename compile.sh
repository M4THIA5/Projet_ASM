#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <file.asm>"
  exit 1
fi

input_file=$1

if [ ! -f "$input_file" ]; then
    echo "File $input_file don't exist"
  exit 1
fi

filename="${input_file%.asm}"
output="${filename}.o"


nasm -felf64 -o $output $input_file

gcc -m64 -no-pie -o $filename $output -lX11

chmod +x $filename
