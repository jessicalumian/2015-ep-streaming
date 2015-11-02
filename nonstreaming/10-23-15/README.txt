Goal: Run ep protocols on ctb (running khmer2.0)  branch, should be same results as 
other file. But this time, get trinity assembly as well.

Code: 

to get assembly at end:

cp /mnt/work/trinity_out_dir/Trinity.fasta .

resource allocation:

sudo chmod a+rwxt /mnt
sudo apt-get -y install git-core

cd /home/ubuntu
rm -fr literate-resting khmer-protocols
git clone https://github.com/dib-lab/literate-resting.git
git clone https://github.com/dib-lab/khmer-protocols.git -b ctb

cd khmer-protocols/mrnaseq

## vim 1-quality.rst # change version number on line 49 to match the release to test

for i in [1-3]-*.rst
do
   /home/ubuntu/literate-resting/scan.py $i || break
done

### START MONITORING (in another SSH session)


for i in [1-3]-*.rst.sh
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


###### Github code (.rst)

================================================
1. Quality Trimming and Filtering Your Sequences
================================================

.. shell start

Boot up an m3.xlarge machine from Amazon Web Services running Ubuntu
14.04 LTS (ami-59a4a230); this has about 15 GB of RAM, and 2 CPUs, and
will be enough to complete the assembly of the Nematostella data
set. If you are using your own data, be aware of your space
requirements and obtain an appropriately sized machine ("instance")
and storage ("volume").

.. note::

   The raw data for this tutorial is available as public snapshot
   snap-f5a9dea7.

Install software
----------------

On the new machine, run the following commands to update the base
software:
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
   git clone --branch v2.0 https://github.com/dib-lab/khmer.git
   cd khmer
   make install

The use of ``virtualenv`` allows us to install Python software without having
root access. If you come back to this protocol in a different terminal session
you will need to run::

        source ~/work/bin/activate

Find your data
--------------

Load the data from `Tulin et al., 2013
<http://www.evodevojournal.com/content/4/1/16>`__ into ``/mnt/data``.
You may need to make the ``/mnt/`` directory writeable by doing::

   sudo chmod a+rwxt /mnt

.. ::

   cd /mnt
   curl -O https://s3.amazonaws.com/public.ged.msu.edu/mrnaseq-subset.tar
   mkdir -p data
   cd data
   tar xvf ../mrnaseq-subset.tar

.. @CTB move mrnaseq-subset.tar onto S3

Check::

   ls /mnt/data/

If you see all the files you think you should, good!  Otherwise, debug.

If you're using the Tulin et al. data provided in the snapshot above,
you should see a bunch of files like::

   0Hour_ATCACG_L002_R1_001.fastq.gz

Link your data into a working directory
---------------------------------------

Rather than *copying* the files into the working directory, let's just
*link* them in -- this creates a reference so that UNIX knows where to
find them but doesn't need to actually move them around. :
::

   cd /mnt
   mkdir -p work
   cd work
   
   ln -fs /mnt/data/*.fastq.gz .

(The ``ln`` command does the linking.)

Now, do an ``ls`` to list the files.  If you see only one entry,
``*.fastq.gz``, then the ln command above didn't work properly.  One
possibility is that your files aren't in /mnt/data; another is that
their names don't end with ``.fastq.gz``.

.. note::

   This protocol takes many hours (days!) to run, so you might not want
   to run it on all the data the first time.  If you're using the
   example data, you can work with a subset of it by running this command
   instead of the `ln -fs` command above::

      cd /mnt/data
      mkdir -p extract
      for file in *.fastq.gz
      do
          gunzip -c ${file} | head -400000 | gzip \
              > extract/${file%%.fastq.gz}.extract.fastq.gz
      done

   This will pull out the first 100,000 reads of each file (4 lines per record)
   and put them in the new ``/mnt/data/extract`` directory.  Then, do::

      rm -fr /mnt/work
      mkdir /mnt/work
      cd /mnt/work
      ln -fs /mnt/data/extract/*.fastq.gz /mnt/work

   to work with the subset data.

Run FastQC on all your files
----------------------------

We can use FastQC to look at the quality of
your sequences::

   fastqc *.fastq.gz

Find the right Illumina adapters
--------------------------------

You'll need to know which Illumina sequencing adapters were used for
your library in order to trim them off. Below, we will use the TruSeq3-PE.fa
adapters
::

   cd /mnt/work
   wget https://sources.debian.net/data/main/t/trimmomatic/0.33+dfsg-1/adapters/TruSeq3-PE.fa

.. note::

   You'll need to make sure these are the right adapters for your
   data.  If they are the right adapters, you should see that some of
   the reads are trimmed; if they're not, you won't see anything
   get trimmed.

Adapter trim each pair of files
-------------------------------

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


Each file with an R1 in its name should have a matching file with an R2 --
these are the paired ends.

The paired sequences output by this set of commands will be in the
files ending in ``qc.fq.gz``, with any orphaned sequences all together
in ``orphans.fq.gz``.

Interleave the sequences
------------------------

Next, we need to take these R1 and R2 sequences and convert them into
interleaved form, for the next step.  To do this, we'll use scripts
from the `khmer package <http://khmer.readthedocs.org>`__, which we
installed above.

Now let's use a for loop again - you might notice this is only a minor
modification of the previous for loop...
::

   for filename in *_R1_*.qc.fq.gz
   do
        # first, make the base by removing .extract.fastq.gz
        base=$(basename $filename .qc.fq.gz)
        echo $base

        # now, construct the R2 filename by replacing R1 with R2
        baseR2=${base/_R1_/_R2_}
        echo $baseR2

        # construct the output filename
        output=${base/_R1_/}.pe.qc.fq.gz

        (interleave-reads.py ${base}.qc.fq.gz ${baseR2}.qc.fq.gz | \
            gzip > $output) && rm ${base}.qc.fq.gz ${baseR2}.qc.fq.gz
   done

.. ::

   echo 1-quality DONE `date` >> ${HOME}/times.out

The final product of this is now a set of files named
``*.pe.qc.fq.gz`` that are paired-end / interleaved and quality
filtered sequences, together with the file ``orphans.fq.gz`` that
contains orphaned sequences.

Finishing up
------------

Make the end product files read-only::

   chmod u-w *.pe.qc.fq.gz orphans.fq.gz

to make sure you don't accidentally delete them.

If you linked your original data files into /mnt/work, you can now do
::

   rm *.fastq.gz

to remove them from this location; you don't need them any more.

Things to think about
~~~~~~~~~~~~~~~~~~~~~

Note that the filenames, while ugly, are conveniently structured with the
history of what you've done to them.  This is a good strategy to keep
in mind.

Evaluate the quality of your files with FastQC again
----------------------------------------------------

We can once again use FastQC to look at the
quality of your newly-trimmed sequences::

   fastqc *.pe.qc.fq.gz

.. Saving the files
.. ----------------

.. Foo goes here.

.. @@CTB

Next stop: :doc:`2-diginorm`.

=================================
2. Applying Digital Normalization
=================================

In this section, we'll apply `digital normalization
<http://arxiv.org/abs/1203.4802>`__ and `variable-coverage k-mer
abundance trimming <https://peerj.com/preprints/890/>`__ to the reads
prior to assembly.  This has the effect of reducing the computational
cost of assembly `without negatively affecting the quality of the
assembly <https://peerj.com/preprints/505/>`__.

.. shell start

.. ::

   set -x
   set -e
   source /home/ubuntu/work/bin/activate

.. note::

   You'll need ~15 GB of RAM for this, or more if you have a LOT of data.

Link in your data
-----------------

Make sure your data is in ``/mnt/work``::

   ls /mnt/work

Run digital normalization
-------------------------

.. ::

   echo 2-diginorm normalize1-pe `date` >> ${HOME}/times.out

Apply digital normalization to the paired-end reads
::

   cd /mnt/work
   normalize-by-median.py -p -k 20 -C 20 -M 4e9 \
     --savegraph normC20k20.ct -u orphans.fq.gz \
     *.pe.qc.fq.gz

Note the ``-p`` in the normalize-by-median command -- when run on
PE data, that ensures that no paired ends are orphaned.  The ``-u`` tells
it that the following filename is unpaired.

Also note the ``-M`` parameter.  This specifies how much memory diginorm
should use, and should be less than the total memory on the computer
you're using. (See `choosing hash
sizes for khmer
<http://khmer.readthedocs.org/en/latest/choosing-hash-sizes.html>`__
for more information.)

Trim off likely erroneous k-mers
--------------------------------

.. ::

   echo 2-diginorm filter-abund `date` >> ${HOME}/times.out

Now, run through all the reads and trim off low-abundance parts of
high-coverage reads
::

   filter-abund.py -V -Z 18 normC20k20.ct *.keep && \
      rm *.keep normC20k20.ct

This will turn some reads into orphans when their partner read is
removed by the trimming.

Rename files
~~~~~~~~~~~~

You'll have a bunch of ``keep.abundfilt`` files -- let's make things prettier.

.. ::
   
   echo 2-diginorm extract `date` >> ${HOME}/times.out

First, let's break out the orphaned and still-paired reads
::

   for file in *.pe.*.abundfilt
   do 
      extract-paired-reads.py ${file} && \
            rm ${file}
   done

We can combine all of the orphaned reads into a single file
::

   gzip -9c orphans.fq.gz.keep.abundfilt > orphans.keep.abundfilt.fq.gz && \
       rm orphans.fq.gz.keep.abundfilt
   for file in *.pe.*.abundfilt.se
   do
      gzip -9c ${file} >> orphans.keep.abundfilt.fq.gz && \
           rm ${file}
   done

We can also rename the remaining PE reads & compress those files
::

   for file in *.abundfilt.pe
   do
      newfile=${file%%.fq.gz.keep.abundfilt.pe}.keep.abundfilt.fq
      mv ${file} ${newfile}
      gzip ${newfile}
   done

This leaves you with a bunch of files named ``*.keep.abundfilt.fq``,
which represent the paired-end/interleaved reads that remain after
both digital normalization and error trimming, together with
``orphans.keep.fq.gz``

Save all these files to a new volume, and get ready to assemble!

.. ::

   echo 2-diginorm DONE `date` >> ${HOME}/times.out

.. shell stop

Next: :doc:`3-big-assembly`.

==============================
3. Running the Actual Assembly
==============================

.. shell start

All of the below should be run in screen, probably...  You will want
at least 15 GB of RAM, maybe more.

(If you start up a new machine, you'll need to go to
:doc:`1-quality` and go through the Install Software section.)

.. note::

   You can start this tutorial with the contents of EC2/EBS snapshot
   snap-7b0b872e.

Installing Trinity
------------------

.. ::

   set -x
   set -e
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

Build the files to assemble
---------------------------

.. ::

   echo 3-big-assembly extractReads `date` >> ${HOME}/times.out

For paired-end data, Trinity expects two files, 'left' and 'right';
there can be orphan sequences present, however.  So, below, we split
all of our interleaved pair files in two, and then add the single-ended
seqs to one of 'em. :
::

   cd /mnt/work
   for file in *.pe.qc.keep.abundfilt.fq.gz
   do
      split-paired-reads.py ${file}
   done
   
   cat *.1 > left.fq
   cat *.2 > right.fq
   
   gunzip -c orphans.keep.abundfilt.fq.gz >> left.fq

Assembling with Trinity
-----------------------

.. ::

   echo 3-big-assembly assemble `date` >> ${HOME}/times.out

Run the assembler!
::

   ${HOME}/trinity*/Trinity --left left.fq \
     --right right.fq --seqType fq --max_memory 14G \
     --CPU ${THREADS:-2}

Note that this last two parts (``--max_memory 14G --CPU ${THREADS:-2}``) is the
maximum amount of memory and CPUs to use.  You can increase (or decrease) them
based on what machine you rented. This size works for the m1.xlarge machines.

Once this completes (on the Nematostella data it might take about 12 hours),
you'll have an assembled transcriptome in
``${HOME}/projects/eelpond/trinity_out_dir/Trinity.fasta``.

You can now copy it over via Dropbox, or set it up for BLAST (see
:doc:`installing-blastkit`).

.. ::

   echo 3-big-assembly DONE `date` >> ${HOME}/times.out

.. shell stop

Next: :doc:`5-building-transcript-families` (or :doc:`installing-blastkit`).
