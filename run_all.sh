#!/bin/bash

RX=1 RY=1 ./run_les.sh
RX=2 RY=1 ./run_les.sh
RX=2 RY=2 ./run_les.sh
RX=4 RY=1 ./run_les.sh
RX=1 RY=4 ./run_les.sh
RX=4 RY=2 ./run_les.sh
RX=2 RY=4 ./run_les.sh
RX=8 RY=1 ./run_les.sh
RX=1 RY=8 ./run_les.sh
RX=16 RY=16 ./run_les.sh

RX=8 RY=8 ./run_les.sh
RX=32 RY=32 ./run_les.sh

RX=64 RY=1 ./run_les.sh
RX=16 RY=8 ./run_les.sh
RX=32 RY=16 ./run_les.sh
RX=64 RY=64 ./run_les.sh
RX=64 RY=32 ./run_les.sh
