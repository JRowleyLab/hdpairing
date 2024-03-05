# hdpairing
hd pairing script that examines the orientation of "self" ligations

Note: It's recommended that you first concatenate all replicates. The paired bam files are found in bwt2 folder of the hicpro output. Concat with samtools cat in1.bam in2.bam in3.bam > out.bam
argument --help

This tool is to obtained hd-pairing signal from hicpro bam files. Any paired bam file will work though.
Usage:
--bampath:      Specify the path the paired bam file.
--fragpath:     Specify the path to the restriction enzyme fragment file used in hicpro.
--sizefile:     Specify the path to the chromosome size file used in hicpro processing.
--res:  Bin size for pairing output, default is 1000 bp.
--outname:      Name of output file.
--tmpdir:       temporary directory for use with sort -T function, default is to create and use a tmp directory in the same folder as bampath
--help:         display this menu.
