#!/bin/bash
bampath=0
help=0
fragpath=0
tmpdir=0
outname=0
res=1000
sizefile=0
echo "Note: It's recommended that you first concatenate all replicates. The paired bam files are found in bwt2 folder of the hicpro output. Concat with samtools cat in1.bam in2.bam in3.bam > out.bam"
menu=`printf "\nThis tool is to obtained hd-pairing signal from hicpro bam files. Any paired bam file will work though.\nUsage:\n--bampath: \tSpecify the path the paired bam file.\n--fragpath: \tSpecify the path to the restriction enzyme fragment file used in hicpro.\n--sizefile: \tSpecify the path to the chromosome size file used in hicpro processing.\n--res: \tBin size for pairing output, default is 1000 bp.\n--outname: \tName of output file.\n--tmpdir: \ttemporary directory for use with sort -T function, default is to create and use a tmp directory in the same folder as bampath\n--help: \tdisplay this menu."`
while test $# -gt 0
do
	case "$1" in
		--bampath)
		bampath=$2
		;;
		--fragpath)
		fragpath=$2
		;;
		--sizefile)
		sizefile=$2
		;;
		--res)
		res=$2
		;;
		--outname)
		outname=$2
		;;
		--tmpdir)
		tmpdir=$2
		;;
		--help) echo "argument $1"
		help=1
		echo "$menu"
		exit 0
		;;
	esac
	shift
done
if [ $bampath == 0 ]
then
echo "You must specify a bam file!......""$menu"
exit 0
fi
if [ $fragpath == 0 ]
then
echo "You must specify a fragments bed file!......""$menu"
exit 0
fi
if [ $sizefile == 0 ]
then
echo "You must specify a chromosome size file!......""$menu"
exit 0
fi
if [ $outname == 0 ]
then
echo "You must specify a name for output files!......""$menu"
exit 0
fi

fullbampath=`readlink -f $bampath`
bamfile=`basename $fullbampath`
bamdir=`echo $fullbampath | sed "s/$bamfile//g"`
#echo "$bamdir" 
if [ $tmpdir == 0 ]
then
tmpdir=$bamdir
fi

mytmp=`echo "$tmpdir""/pairingtmp"`
mkdir $mytmp
pair=`echo "$outname""_deduppairs"`
nonpair=`echo "$outname""_dedupnonpairs"`

echo "Getting oriented reads for ""$bampath"" and sorting using temporary directory ""$mytmp"
bamToBed -bedpe -i $bampath | awk '{if (($9 == $10) && ($1 == $4) && ($8 >= 10)) print $0}' | intersectBed -wa -a stdin -wb -b $fragpath | awk '{print $4"\t"$5"\t"$6"\t"$1"\t"$2"\t"$3"\t"$11"\t"$12"\t"$13"\t"$14}' | intersectBed -wa -a stdin -wb -b $fragpath | awk '{if ($10 == $14) print $0}' | sort -T $mytmp -k 1,1 -V -k 2bn,2b --stable -k 3bn,3b --stable -k 5bn,5b --stable -k 6bn,6b --stable | cut -f 1-9 | uniq -c | awk '{print $8"\t"$9"\t"$10}' > $pair

echo "Getting background reads for ""$bampath"" and sorting using temporary directory ""$mytmp"
bamToBed -bedpe -i $bampath | awk '{if (($9 != $10) && ($1 == $4) && ($8 >= 10)) print $0}' | intersectBed -wa -a stdin -wb -b $fragpath | awk '{print $4"\t"$5"\t"$6"\t"$1"\t"$2"\t"$3"\t"$11"\t"$12"\t"$13"\t"$14}' | intersectBed -wa -a stdin -wb -b $fragpath | awk '{if ($10 == $14) print $0}' | sort -T $mytmp -k 1,1 -V -k 2bn,2b --stable -k 3bn,3b --stable -k 5bn,5b --stable -k 6bn,6b --stable | cut -f 1-9 | uniq -c | awk '{print $8"\t"$9"\t"$10}' > $nonpair

finalout=`echo "$outname""_binnedPairRatio.bedgraph"`
pairout=`echo "$outname""_binnedPairs.bedgraph"`
backout=`echo "$outname""_binnedBackground.bedgraph"`
echo "Binning paired reads into ""$finalout"
pairtmpout=`echo "$mytmp""/pairtmp"`
cat $sizefile | awk -v bin=$res '{for (i=0;i<=$2;i+=bin) print $1"\t"i"\t"i+bin}' | intersectBed -c -a stdin -b $pair | intersectBed -c -a stdin -b $nonpair > $pairtmpout
awk '{if ($4 > 0) print $1"\t"$2"\t"$3"\t"$4}' $pairtmpout > $pairout
awk '{if ($5 > 0) print $1"\t"$2"\t"$3"\t"$5}' $pairtmpout > $backout
myav=`awk '{sum += ($5+$4)} END {print sum/NR}' $pairtmpout`
awk -v myav=$myav '{if ($4 > 0) print $1"\t"$2"\t"$3"\t"$4/(($5+$4)+myav)}' $pairtmpout > $finalout

echo "Cleaning up..."
rm -r $mytmp
echo "Finished!"
