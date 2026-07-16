#!/bin/bash
# ==============================================================================
# DC Synthesis Automation Script (run.sh)
# ==============================================================================

# 1. 创建必要的子文件夹
mkdir -p work
mkdir -p reports
mkdir -p outputs

# 2. 给予脚本运行权限并清理上一次的缓存文件
rm -rf ./work/*
rm -rf filenames.log command.log

# 3. 启动 Design Compiler 执行综合
echo "[INFO] Starting Design Compiler Synthesis..."
dc_shell -f synth.tcl | tee dc_system.log
echo "[INFO] Synthesis completed. Please check ./reports and ./outputs."