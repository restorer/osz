#!/bin/sh

gcc ./makezimg.c -o ./makezimg &> ./errors.log
cat ./errors.log
