EOS_DIR=/root/eos
nohup nodeos --data-dir=$EOS_DIR/data --config-dir=$EOS_DIR/config --snapshot $EOS_DIR/data/snapshots/latest.bin > log 2>&1 &
