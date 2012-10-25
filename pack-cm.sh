#!/bin/bash

PROJECT_ROOT=$PWD

(
cd tools/pack
CRANE_IMAGE_OUT=${PROJECT_ROOT}/out/target/product/cubieboard ./pack -c sun4i -p crane -b cubieboard
)

