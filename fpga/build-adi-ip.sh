#!/bin/bash

# // Author: Xianjun Jiao <putaoshu@msn.com>
# // SPDX-FileCopyrightText: 2025 Xianjun Jiao
# // SPDX-License-Identifier: Apache-2.0 license

echo "usage:"
echo "build-adi-ip.sh \$XILINX_DIR"

if [ "$#" -ne 1 ]; then
  exit 1
fi

XILINX_DIR=$1

XILINX_ENV_FILE=$XILINX_DIR/Vivado/2022.2/settings64.sh
echo "Expect env file $XILINX_ENV_FILE"

if [ -f "$XILINX_ENV_FILE" ]; then
  echo "$XILINX_ENV_FILE is found!"
else
  echo "$XILINX_ENV_FILE is not correct. Please check!"
  exit 1
fi

if test -d "adi-hdl"; then
  echo "Found adi-hdl"
else
  echo "adi-hdl NOT found!"
  exit 1
fi

git submodule init adi-hdl
git submodule update adi-hdl
cd ./adi-hdl/
git reset --hard
git fetch
git checkout 2022_R2
git reset --hard 2022_R2
source $XILINX_ENV_FILE
cd library/
make

