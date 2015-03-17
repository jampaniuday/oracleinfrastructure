#!/bin/bash
#$Id: _base_script_block.sh,v 1.1 2012-05-07 13:47:27 remik Exp $

LOG_DIR=/var/tmp/test_invalids
mkdir -p $LOG_DIR

(. ./test_invalids.wrap 2>&1) | tee $LOG_DIR/test_invalids_log_$1.`date '+%Y-%m-%d--%H:%M:%S'`