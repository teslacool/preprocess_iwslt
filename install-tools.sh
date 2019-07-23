#!/usr/bin/env bash
set -e
MAIN_PATH=$PWD
TOOLS_PATH=$PWD/tools
MOSES_DIR=$TOOLS_PATH/mosesdecoder
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$FASTBPE_DIR/fast
mkdir -p $TOOLS_PATH
cd $TOOLS_PATH
if [ ! -d "$MOSES_DIR" ]; then
  echo "Cloning Moses from GitHub repository..."
  git clone https://github.com/moses-smt/mosesdecoder.git
fi
if [ ! -d "$FASTBPE_DIR" ]; then
  echo "Cloning fastBPE from GitHub repository..."
  git clone https://github.com/glample/fastBPE
fi
if [ ! -f "$FASTBPE" ]; then
  echo "Compiling fastBPE..."
  cd fastBPE
  g++ -std=c++11 -pthread -O3 fastBPE/main.cc -IfastBPE -o fast
  cd ..
fi
cd $MAIN_PATH
pip install -r requirements.txt