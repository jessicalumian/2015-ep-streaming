Goal: Added up until trinity!

Future Goal: get trimmomatic into streaming mode, fix trim-low-abund.py
to allow for Z and C specificity


Code: 

to get assembly at end:

cp /mnt/work/trinity_out_dir/Trinity.fasta .

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


bash 1-quality.rst.sh




## SAR monitoring commands ##

# to run
   sudo apt-get install sysstat -y
   sar -u -r -d -o times.dat 1

# to extract

 sar -d -p -f times.dat > disk.txt
   sar -u -f times.dat > cpu.txt
   sar -r -f times.dat > ram.txt
   gzip *.txt

#### Github code - .rst format

================================================
Working page for 2015-ep-streaming - integrating sar cmds
================================================

.. shell start

::

   sudo apt-get update && \
   sudo apt-get -y install screen git curl gcc make g++ python-dev unzip \
            default-jre pkg-config libncurses5-dev r-base-core r-cran-gplots \
            python-matplotlib python-pip python-virtualenv sysstat fastqc \
            trimmomatic bowtie samtools blast2
.. ::

   set -x
   set -e

   echo Clearing times.out
   touch ${HOME}/times.out
   mv -f ${HOME}/times.out ${HOME}/times.out.bak
   echo 1-quality INSTALL `date` >> ${HOME}/times.out

Install `khmer <http://khmer.readthedocs.org>`__ from its source code.
::

   cd ~/
   python2.7 -m virtualenv work
   source work/bin/activate
   pip install -U setuptools
   git clone --branch cleanup/semistreaming https://github.com/dib-lab/khmer.git
   cd khmer
   make install
::

   sudo chmod a+rwxt /mnt

.. ::

   cd /mnt
   curl -O https://s3.amazonaws.com/public.ged.msu.edu/mrnaseq-subset.tar
   mkdir -p data
   cd data
   tar xvf ../mrnaseq-subset.tar

.. @CTB move mrnaseq-subset.tar onto S3


 :
::

   cd /mnt
   mkdir -p work
   cd work
   
   ln -fs /mnt/data/*.fastq.gz .


We can use FastQC to look at the quality of
your sequences::

   fastqc *.fastq.gz

::

   cd /mnt/work
   wget https://sources.debian.net/data/main/t/trimmomatic/0.33+dfsg-1/adapters/TruSeq3-PE.fa

.. ::

   echo 1-quality TRIM `date` >> ${HOME}/times.out

(From this point on, you may want to be running things inside of
screen, so that you can leave it running while you go do something
else; see :doc:`../amazon/using-screen` for more information.)

Run
::

   rm -f orphans.fq.gz

   for filename in *_R1_*.fastq.gz
   do
        # first, make the base by removing fastq.gz
        base=$(basename $filename .fastq.gz)
        echo $base
        
        # now, construct the R2 filename by replacing R1 with R2
        baseR2=${base/_R1_/_R2_}
        echo $baseR2
        
        # finally, run Trimmomatic
        TrimmomaticPE ${base}.fastq.gz ${baseR2}.fastq.gz \
           ${base}.qc.fq.gz s1_se \
           ${baseR2}.qc.fq.gz s2_se \
           ILLUMINACLIP:TruSeq3-PE.fa:2:40:15 \
           LEADING:2 TRAILING:2 \
           SLIDINGWINDOW:4:2 \
           MINLEN:25
        
        # save the orphans
        gzip -9c s1_se s2_se >> orphans.fq.gz
        rm -f s1_se s2_se
   done

   (for filename in *_R1_*.qc.fq.gz
   do
      base=$(basename $filename .qc.fq.gz)
      baseR2=${base/_R1_/_R2_}
      output=${base/_R1_/}.pe.qc.fq.gz

      interleave-reads.py ${base}.qc.fq.gz ${baseR2}.qc.fq.gz  

   done && zcat orphans.fq.gz && \
      echo 1-quality DONE `date` >> ${HOME}/times.out && \
      echo 2-diginorm normalize1-pe `date` >> ${HOME}/times.out) | \
      trim-low-abund.py -V -k 20 -Z 20 -C 3 - -o - -M 4e9 --diginorm \
      --diginorm-coverage=20 -C 2 -Z 18 -k 20 -V | \
      (echo 2-diginorm filter-abund `date` >> ${HOME}/times.out && \
      echo 2-diginorm extract `date` >> ${HOME}/times.out && \
      extract-paired-reads.py --gzip  -p paired.gz -s single.gz && \
      echo 2-diginorm DONE `date` >> ${HOME}/times.out)
   
Installing Trinity
------------------
::

   source /home/ubuntu/work/bin/activate
   echo 3-big-assembly compileTrinity `date` >> ${HOME}/times.out

To install Trinity:
::
   
   cd ${HOME}
   
   wget https://github.com/trinityrnaseq/trinityrnaseq/archive/v2.0.4.tar.gz \
     -O trinity.tar.gz
   tar xzf trinity.tar.gz
   cd trinityrnaseq*/
   make |& tee trinity-build.log

::

   echo 3-big-assembly extractReads `date` >> ${HOME}/times.out
   cd /mnt/work
   zcat paired.gz | \
   split-paired-reads.py -1 left.fq -2 right.fq paired.gz | \
   gunzip -c orphans.fq.gz >> left.fq
   

   echo 3-big-assembly assemble `date` >> ${HOME}/times.out

Now we will be running Trinity:
::
   cd /mnt/work
   ${HOME}/trinity*/Trinity --left left.fq --right right.fq --seqType fq --max_memory 14G --CPU ${THREADS:-2}
   
   echo 3-big-assembly DONE `date` >> ${HOME}/times.out

.. shell stop