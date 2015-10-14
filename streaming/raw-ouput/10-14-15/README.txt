Goal: Run same process/code as 10-10-15, but measure size of output files. 
In future runs, trim-low-abund.py params will be modified, so I want to 
be able to compare file sizes from here on out.

note - it seems like working files were being deleted between 1-rst and 2-rst, so diginorm never happened, and resource allocation may not be accurate.  This is the last file chronologically with that possible problem.

Code: (copied from 10-10-15 README.txt)

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

1-rst is same as ctb branch, just without the interleave-reads.py loop (last loop on training page)

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

     normalize-by-median.py -k 20 -C 20 -M 4e9 - -o - | \
     trim-low-abund.py -V -k 20 -Z 20 -C 3 - -o - -M 4e9 | \
     extract-paired-reads.py --gzip  -p paired.gz -s single.gz

.. shell stop

