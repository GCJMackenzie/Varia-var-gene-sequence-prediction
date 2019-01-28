#!/bin/bash

## 1. Add the path to Varia1_1 directory to your pathway
## 2. Run script with command line: Varia.sh <name of fasta file> <identity value for initial blast>

##obtains current path to Varia directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "$1" = "" ]
then
	echo "No filename specified, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi
CHECK=$(echo $1 | cut -d '.' -f2)
if [ "$CHECK" != "fasta" ]
then
	echo "filename is not in a fasta format, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi

CHECK=$(head $1)
if [ "$CHECK" = '' ]
then
	echo "No file called $1 was found in this directory"
	exit
fi
FILE=$(basename $1 .fasta)



IDENT=$2
if [ "$IDENT" = "" ]
then
	echo "No Identity score detected, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi


if ! echo $IDENT | egrep -q '^[0-9]+$';
then
	echo "Identity score must be an integer between 1 and 100, input should be: Varia.sh [input_file.fasta] [identity score]"
	exit
fi

if [ $IDENT -gt 100 ] || [ $IDENT -lt 1 ]
then
	echo "Identity score out of range, keep identity score between 1 and 100"
	exit
fi

##makes directories to sort output files 
mkdir ./$FILE-$IDENT-Varia_Out
##mkdir ./$FILE-$IDENT-Varia_Out/aln_files
mkdir ./$FILE-$IDENT-Varia_Out/cluster_files
mkdir ./$FILE-$IDENT-Varia_Out/length
mkdir ./$FILE-$IDENT-Varia_Out/chromosomes
mkdir ./$FILE-$IDENT-Varia_Out/links
mkdir ./$FILE-$IDENT-Varia_Out/labels
mkdir ./$FILE-$IDENT-Varia_Out/domains
mkdir ./$FILE-$IDENT-Varia_Out/coverage
mkdir ./$FILE-$IDENT-Varia_Out/filedump
mkdir ./$FILE-$IDENT-Varia_Out/plots
mkdir ./$FILE-$IDENT-Varia_Out/axis
mkdir ./$FILE-$IDENT-Varia_Out/axis_label
mkdir ./$FILE-$IDENT-Varia_Out/summaries

##temporary copy of input file made
cp $FILE.fasta $FILE.alt.fasta
##end of file line added to temp copy
echo '>END OF FILE' >> $FILE.alt.fasta
##list of sample names and their starting lines added to names .txt
grep -n '>' $FILE.alt.fasta > names.txt

##counter set to 1, total sample names set to the number of lines in names.txt
COUNT=1
TOT=$(wc -l names.txt| head -n1| awk '{print $1;}')
##this loop runs for each name in names.txt not including the end of file line
while [ $COUNT -lt $TOT ]
do
	##sample name extracted from names.txt
	NAME=$(awk -v line="$COUNT" 'NR==line {print}' names.txt| head -n1| cut -d ">" -f2)
	##the line where the sample begins is set
	BLINE=$(awk -v line="$COUNT" 'NR==line {print}' names.txt| head -n1| cut -d ":" -f1)
	
	##the line where the sample ends is set
	ELINE=$(awk -v line="$((COUNT +1))" 'NR==line {print}' names.txt| head -n1| cut -d ":" -f1)
	ELINE=$((ELINE -1))
	
	##the current sample is copied into a temporary fasta file
	awk -v first="$BLINE" -v last="$ELINE" 'NR>=first&&NR<=last' $FILE.alt.fasta > $NAME.fasta
	
	##sample is blast searched against the database, then the length of the sequence is added
	blastn -task megablast -dust no -num_threads 8 -outfmt 6 -evalue 1e-80 -max_target_seqs 2000  -db $DIR/vardb/vardb -query $NAME.fasta -out $NAME.blast
	
	perl $DIR/scripts/helper.putlengthfasta2Blastm8.pl $NAME.fasta $DIR/vardb/Pf3K.vargenes.na.fasta $NAME.blast
	
	##fasta index made for temp fasta file
	samtools faidx $NAME.fasta
	
	##genes of interest added to genes.fasta file
	n=$(awk -v identity="$IDENT" '$3>identity && $4>200' $NAME.blast.length | cut -f 2 | awk ' {n=n" "$FILE } END {print n}')
	samtools faidx $DIR/vardb/Pf3K.vargenes.na.fasta $n >> $NAME.genes.fasta
	##cat $NAME.fasta >> $NAME.genes.fasta
	BLAST=$(awk '$3>99 && $4>200' $NAME.blast | wc -l)

	##genes file blast searched against itself and lengths added
	blastn -task megablast -dust no -num_threads 8 -outfmt 6 -evalue 1e-40 -max_target_seqs 2000  -subject $NAME.genes.fasta -query $NAME.genes.fasta -out $NAME.Self.blast
	perl $DIR/scripts/helper.putlengthfasta2Blastm8.pl $NAME.genes.fasta $NAME.genes.fasta $NAME.Self.blast
	##genes to be passed to mcl added to txt file
	awk '$3>99 &&  ($4>= (0.8*$13) || $4 >= (0.8*$14) )' $NAME.Self.blast.length  | cut -f 1,2,4 > $NAME.formcl.txt

	
	## mcl forms cluster groups of the genes
	mcl $NAME.formcl.txt  --abc -o $NAME.clusters.txt
	
	##finds total number of lines in cluster file
	CTOT=$(wc -l $NAME.clusters.txt| head -n1| awk '{print $1;}')
	
	##cluster counter set to 1
	CCOUNT=1
	
	##variables storing the number of clusters and lone genes are set to 0
	CCLUSTER=0
	CSINGLE=0
	
	##loops through lines in the cluster file
	while [ $CCOUNT -le $CTOT ]
	do
		##counts the number of genes on each line, ifi it is 1 then 1 is added to the lone genes counter, if it is >1 then 1 is added to the cluster counter
		CHECK=$(awk -v line="$CCOUNT" 'NR==line {print}' $NAME.clusters.txt| wc -w)
		if [ $CHECK == 1 ]
		then
			CSINGLE=$((CSINGLE + 1))
		else
			CCLUSTER=$((CCLUSTER + 1))
		fi
				
		CCOUNT=$((CCOUNT +1))
	done
	
	##sends line summarising the cluster counter and lone genes counter to cluster summary file
	CRESULT="$NAME has $CCLUSTER cluster(s) and $CSINGLE lone match(es)."
	echo $CRESULT >> mcl_summary_$FILE.txt
	##runs the pythonsort script to make the chromosomes file for sample and the fasta file for blast to use to make a links file
	python $DIR/scripts/pythonsort.py $NAME
	
	##blast run to perform self comparison of fasta file generated from pythonsort
	blastn -task megablast -dust no -num_threads 8 -outfmt 6 -evalue 1e-40 -max_target_seqs 2000  -subject $NAME.forblast.fasta -query $NAME.forblast.fasta -out $NAME.link.blast
	perl $DIR/scripts/helper.putlengthfasta2Blastm8.pl $NAME.forblast.fasta $NAME.forblast.fasta $NAME.link.blast

	##runs the labelfile python script to create file containing domain names for sample
	python $DIR/scripts/add_domain.py $NAME $DIR

	
	##adds blast entries to the links file then re-orders the columns into correct format for the link file
	awk '$3>99 && $4>200 && $1!=$2' $NAME.link.blast.length  | cut -f 1,7,8,2,9,10 >> $NAME.links.txt
	awk '{print $1 "\t" $3 "\t" $4 "\t" $2 "\t" $5 "\t" $6}' $NAME.links.txt > $NAME.linked.txt
	
	## colour added to links using add_color.py
	python $DIR/scripts/add_color.py $NAME
	
	##coverage files for each cluster generated using add_coverage.py
	python $DIR/scripts/add_coverage.py $NAME
	
	##abridges coverage files for each cluster using give_median.py
	while read p; do
		for x in depth.$p.plot; do
		python $DIR/scripts/give_median.py $x 
		done
		mv depth.$p.plot ./$FILE-$IDENT-Varia_Out/filedump/$NAME.depth.$p.plot
		##adds each clusters coverage file to the main coverage file for Circos
		cat plotme.txt >> $NAME.Plot.median.coverage.plot
	done <$NAME.plotlist.txt
	
	##generates the Y axis for each clusters coverage plot
	python $DIR/scripts/add_axis.py $NAME
	
	## removes any mirrored links generated by the self blast 
	python $DIR/scripts/remove_twins.py $NAME
	
	##finds max coverage value
	MAX=$(awk '{print $4}' $NAME.axis_label_max.txt | head -n1)
	MAX=$((MAX + 1))
	##calculates how many lines should be present on coverage plot by dividing 1 by the value of MAX
	RANGE=$(bc <<<"scale=4; 1 / $MAX")
	RANGE=0${RANGE}r

	##Circos plot generated
	circos -silent -conf $DIR/scripts/Varia.conf -param chromosome_file=$NAME.chromosome.txt -param link_file=$NAME.untwin_link.txt -param domain_file=$NAME.domains.txt -param domain_label_file=$NAME.domain_label.txt -param coverage_file=$NAME.Plot.median.coverage.plot -param axis_file=$NAME.axis_line.txt -param axis_min=$NAME.axis_label_min.txt -param axis_max=$NAME.axis_label_max.txt -param max=$MAX -param range=$RANGE -outputfile $NAME.circos.plot.png
	
	##cluster summary genrated
	python $DIR/scripts/get_clusters.py $NAME $DIR
	
	##each cluster is blast searched against its largest sequence to help find how many samples in the cluster are 80% length of the largest sequence
	while read p; do
	blastn -task megablast -dust no -num_threads 8 -outfmt 6 -evalue 1e-40 -max_target_seqs 2000  -subject $p.db_seq.txt -query $p.query_seq.txt -out $p.80.blast
		
	done <$NAME.listclust.txt
	
	##final summary file generated
	python $DIR/scripts/give_final.py $NAME
	
	
	##sample specific temporary files deleted
	while read p; do
	rm $p.80.blast
	rm $p.query_seq.txt
	rm $p.db_seq.txt
	done <$NAME.listclust.txt
	rm $NAME.listclust.txt
	rm plotme.txt
	##sample specific temporary files moved to filedump directory
	mv $NAME.fasta ./$FILE-$IDENT-Varia_Out/filedump/$NAME.fasta
	mv $NAME.fasta.fai ./$FILE-$IDENT-Varia_Out/filedump/$NAME.fasta.fai
	mv $NAME.blast ./$FILE-$IDENT-Varia_Out/filedump/$NAME.blast
	mv $NAME.blast.length ./$FILE-$IDENT-Varia_Out/filedump/$NAME.blast.length
	mv $NAME.formcl.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.formcl.txt
	mv $NAME.genes.fasta ./$FILE-$IDENT-Varia_Out/filedump/$NAME.genes.fasta
	mv $NAME.Self.blast ./$FILE-$IDENT-Varia_Out/filedump/$NAME.Self.blast
	mv $NAME.forblast.fasta ./$FILE-$IDENT-Varia_Out/filedump/$NAME.forblast.fasta
	mv $NAME.link.blast ./$FILE-$IDENT-Varia_Out/filedump/$NAME.link.blast
	mv $NAME.link.blast.length ./$FILE-$IDENT-Varia_Out/filedump/$NAME.link.blast.length
	mv $NAME.links.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.links.txt
	mv $NAME.link.txt ./$FILE-$IDENT-Varia_Out/links/$NAME.link.txt
	mv $NAME.linked.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.linked.txt
	mv $NAME.plotlist.txt ./$FILE-$IDENT-Varia_Out/filedump/$NAME.plotlist.txt
	
	##sample specific result files moved to appropriate directories
	mv $NAME.clusters.txt ./$FILE-$IDENT-Varia_Out/cluster_files/$NAME.clusters.txt
	mv $NAME.Self.blast.length ./$FILE-$IDENT-Varia_Out/length/$NAME.Self.blast.length
	mv $NAME.chromosome.txt ./$FILE-$IDENT-Varia_Out/chromosomes/$NAME.chromosome.txt
	mv $NAME.domain_label.txt ./$FILE-$IDENT-Varia_Out/labels/$NAME.domain_label.txt
	mv $NAME.domains.txt ./$FILE-$IDENT-Varia_Out/domains/$NAME.domains.txt
	mv $NAME.untwin_link.txt ./$FILE-$IDENT-Varia_Out/links/$NAME.untwin_link.txt
	mv $NAME.axis_line.txt ./$FILE-$IDENT-Varia_Out/axis/$NAME.axis_line.txt
	mv $NAME.axis_label_min.txt ./$FILE-$IDENT-Varia_Out/axis_label/$NAME.axis_label_min.txt
	mv $NAME.axis_label_max.txt ./$FILE-$IDENT-Varia_Out/axis_label/$NAME.axis_label_max.txt
	mv $NAME.Plot.median.coverage.plot ./$FILE-$IDENT-Varia_Out/coverage/$NAME.Plot.median.coverage.plot
	mv $NAME.circos.plot.png ./$FILE-$IDENT-Varia_Out/plots/$NAME.circos.plot.png
	mv $NAME.circos.plot.svg ./$FILE-$IDENT-Varia_Out/plots/$NAME.circos.plot.svg
	mv $NAME.cluster_summary.txt ./$FILE-$IDENT-Varia_Out/summaries/$NAME.cluster_summary.txt
	mv $NAME.final_summary.txt ./$FILE-$IDENT-Varia_Out/summaries/$NAME.final_summary.txt
	COUNT=$((COUNT +1))
done

##remaining temporary files removed
rm names.txt
rm $FILE.alt.fasta

##summary file moved into the Varia1_Out directory
mv mcl_summary_$FILE.txt ./$FILE-$IDENT-Varia_Out/mcl_summary_$FILE.txt
