Steps:

-run protocol from literate-resting repo on m3.xlarge AWS EC2 ubuntu 14.04

(non-streaming here: https://github.com/dib-lab/literate-resting/blob/master/kp/eel-pond.rst, streaming here: https://github.com/dib-lab/khmer-protocols/tree/jem-streaming, be sure to change branch from ctb to jem-streaming for streaming)

-use sar to measure computational resources (https://github.com/ctb/sartre/blob/master/README.txt), use screen run in new window

-use cyberduck to download disk.txt.gz, cpu.txt.gz, ram.txt.gz

-use sartre/extract.py to extract log.out file (move *.txt.gz and time.* files from sar to local sartre branch, run script, move log.out back to correct folder, remove *.txt.gz and time.* files —- perhaps there is a better way to do this?)

-load into R, use existing script to generate graph

test


streaming:

Steps:

-run protocol from literate-resting repo on m3.xlarge AWS EC2 ubuntu 14.04

sudo chmod a+rwxt /mnt
sudo apt-get -y install git-core



-use sar to measure computational resources (https://github.com/ctb/sartre/blob/master/README.txt), use screen run in new window

-use cyberduck to download disk.txt.gz, cpu.txt.gz, ram.txt.gz

-use sartre/extract.py to extract log.out file (move *.txt.gz and time.* files from sar to local sartre branch, run script, move log.out back to correct folder, remove *.txt.gz and time.* files —- perhaps there is a better way to do this?)

-load into R, use existing script to generate graph