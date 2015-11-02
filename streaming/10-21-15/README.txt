Goal: Using semistreaming khmer branch/diginorm param in trim-low-abund, and 
observe file sizes/number of reads in paired and single.gz to compare
with ctb branch 

Code: (partially copied from 10-19-15 README.txt)

command to look at file sizes:

gunzip -c *.gz | wc -l

resource allocation:

sudo chmod a+rwxt /mnt
sudo apt-get -y install git-core

cd /home/ubuntu
rm -fr literate-resting khmer-protocols
git clone https://github.com/dib-lab/literate-resting.git
git clone https://github.com/dib-lab/khmer-protocols.git -b jem-streaming

cd khmer-protocols/mrnaseq

## vim 1-quality.rst # change version number on line 49 to match the release to test

for i in [1-2]-*.rst
do
   /home/ubuntu/literate-resting/scan.py $i || break
done

### START MONITORING (in another SSH session)


for i in [1-2]-*.rst.sh
do
   bash $i |& tee ${i%%.rst.sh}.out || break
done


## SAR monitoring commands ##

# to run
   sudo apt-get install sysstat -y
   sar -u -r -d -o times.dat 1

# to extract

 sar -d -p -f times.dat > disk.txt
   sar -u -f times.dat > cpu.txt
   sar -r -f times.dat > ram.txt
   gzip *.txt


############ Github code

1-rst differences from ctb branch: no interleave-reads loop, and khmer checkout
goes to semistreaming version

jem-streaming version:

cd ~/
python2.7 -m virtualenv work
source work/bin/activate
pip install -U setuptools
git clone --branch cleanup/semistreaming https://github.com/dib-lab/khmer.git
cd khmer
make install

ctb version:

cd ~/
python2.7 -m virtualenv work
source work/bin/activate
pip install -U setuptools
git clone --branch cleanup/semistreaming https://github.com/dib-lab/khmer.git
cd khmer
make install

2-rst is the following

.. shell start
::

for filename in *_R1_*.qc.fq.gz
do
     (base=$(basename $filename .qc.fq.gz)
     baseR2=${base/_R1_/_R2_}
     output=${base/_R1_/}.pe.qc.fq.gz)

     interleave-reads.py ${base}.qc.fq.gz ${baseR2}.qc.fq.gz  

done | \

     trim-low-abund.py -V -k 20 -Z 20 -C 3 - -o - -M 4e9 --diginorm | \
     extract-paired-reads.py --gzip  -p paired.gz -s single.gz

.. shell stop



