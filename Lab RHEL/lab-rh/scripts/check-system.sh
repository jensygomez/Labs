#!/bin/bash
echo "=== Estado del Sistema ==="
hostname
uname -r
df -h
free -m
ps aux | head
