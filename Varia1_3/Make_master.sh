#!/bin/bash
##script for creating master test tables used during testing of Varia
##takes the FULL PATH to the directory of results from Varia for a sample. and the IDfilter
SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RETURN=$(pwd)
DIR=$1
IDFILT=$2
cd $DIR
##retrieves file containing the sample names present in results
cp ./filedump/names.txt names.txt
while read p;
	do x=$(echo $p | cut -d '>' -f 2)
	if [ "$x" != "END OF FILE" ]
	then
		echo $x >> name.txt
	fi
done < names.txt
rm names.txt
cd filedump

##counts blast hits of each sample and adds to master table
while read p;
	do wc -l ${p}.blast | awk '{print $2 "\t" $1}' >> Master_onecol.txt
done < $DIR/name.txt

##filters blast hits for each sample for identity and bp length then adds to column 2 of table
while read p;
	do
	awk -v filter=$IDFILT '$3>filter && $4>200' $p.blast |wc -l | awk -v ident="$p" '{print ident "\t" $1}' >> dbfilt.txt
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_onecol.txt dbfilt.txt Master_twocol.txt
rm dbfilt.txt
rm Master_onecol.txt

##adds no. of self blast hits for samples to column 3
while read p;
	do
	FILECHECK=$(ls -F | grep ${p}.Self.blast)
	if [ "$FILECHECK" != "" ]
	then
		wc -l ${p}.Self.blast | awk '{print $2 "\t" $1}' >> Selfunfilt.txt
	else
		echo -e "$p.Self.blast\t0" >> Selfunfilt.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_twocol.txt Selfunfilt.txt Master_threecol.txt
rm Master_twocol.txt
rm Selfunfilt.txt

##adds number of filtered hits for each sample to column 4
while read p;
	do
	FILECHECK=$(ls -F | grep ${p}.formcl.txt)
	if [ "$FILECHECK" != "" ]
	then
		wc -l ${p}.formcl.txt | awk '{print $2 "\t" $1}' >> Selffilt.txt
	else
		echo -e "$p.formcl.txt\t0" >> Selffilt.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_threecol.txt Selffilt.txt Master_fourcol.txt
rm Master_threecol.txt
rm Selffilt.txt

mv Master_fourcol.txt $DIR/cluster_files/Master_fourcol.txt
cd $DIR/cluster_files

##counts the number of clusters each sample generated and adds to column five
while read p;
	do 
	FILECHECK=$(ls -F | grep ${p}.clusters.txt)
	if [ "$FILECHECK" != "" ]
	then
		wc -l ${p}.clusters.txt | awk '{print $2 "\t" $1}' >> clustnum.txt
	else
		echo -e "$p.clusters.txt\t0" >> clustnum.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_fourcol.txt clustnum.txt Master_fivecol.txt
rm Master_fourcol.txt
rm clustnum.txt

mv Master_fivecol.txt $DIR/filedump/Master_fivecol.txt
cd $DIR/filedump

##adds the number of links between clusters were found for each sample to column six
while read p;
	do
	FILECHECK=$(ls -F | grep ${p}.link.blast)
	if [ "$FILECHECK" != "" ]
	then
		wc -l ${p}.link.blast | awk '{print $2 "\t" $1}' >> link_unfilt.txt
	else
		echo -e "$p.link.blast\t0" >> link_unfilt.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_fivecol.txt link_unfilt.txt Master_sixcol.txt
rm Master_fivecol.txt
rm link_unfilt.txt

mv Master_sixcol.txt $DIR/links/Master_sixcol.txt
cd $DIR/links

##adds the number of filtered links from each sample to column 7
while read p;
	do
	FILECHECK=$(ls -F | grep ${p}.untwin_link.txt)
	if [ "$FILECHECK" != "" ]
	then
		wc -l ${p}.untwin_link.txt | awk '{print $2 "\t" $1}' >> link_filt.txt
	else
		echo -e "$p.untwin_link.txt\t0" >> link_filt.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_sixcol.txt link_filt.txt Master_sevcol.txt
rm Master_sixcol.txt
rm link_filt.txt

mv Master_sevcol.txt $DIR/cluster_files/Master_sevcol.txt
cd $DIR/cluster_files

##checks if sample name is present in any clusters (will always be no unless it was in the db) and adds it to column 8
while read p;
	do 
	FILECHECK=$(ls -F | grep $p.clusters.txt)
	if [ "$FILECHECK" != "" ]
	then
		ISHERE=$(grep "$p" $p.clusters.txt)
		if [ "$ISHERE" != "" ]
			then echo -e "$p\tYes" >> match1.txt
			else echo -e "$p\tNo" >> match1.txt
		fi
	else
		echo -e "$p\tAbs" >> match1.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_sevcol.txt match1.txt Master_octcol.txt
rm Master_sevcol.txt
rm match1.txt

##checks if sample name is present in cluster 1 (will always be no unless it was in the db) and adds it to column 9
while read p;
	do 
	FILECHECK=$(ls -F | grep $p.clusters.txt)
	if [ "$FILECHECK" != "" ]
	then
		ISHERE=$(head -n1 $p.clusters.txt | grep "$p" )
		if [ "$ISHERE" != "" ]
			then echo -e "$p\tYes" >> match2.txt
			else echo -e "$p\tNo" >> match2.txt
		fi
	else
		echo -e "$p\tAbs" >> match2.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_octcol.txt match2.txt Master_noncol.txt
rm Master_octcol.txt
rm match2.txt

##adds the length of cluster 1 to column 10
TAB=$(echo -e '\t')
while read p;
	do
	FILECHECK=$(ls -F | grep $p.clusters.txt)
	if [ "$FILECHECK" != "" ]
	then
		TCOUNT=$(head -n1 $p.clusters.txt | grep -o "$TAB" | wc -l)
		TCOUNT=$(($TCOUNT + 1))
		echo -e "$p\t$TCOUNT" >> clustsize.txt
	else
		echo -e "$p\t0" >> clustsize.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_noncol.txt clustsize.txt Master_deccol.txt
rm Master_noncol.txt
rm clustsize.txt

mv Master_deccol.txt $DIR/summaries/Master_deccol.txt
cd $DIR/summaries

##adds the name of the largest sequence in cluster 1 to column 11
while read p;
	do 
	FILECHECK=$(ls -F | grep $p.final_summary.txt)
	if [ "$FILECHECK" != "" ]
	then
		IN=$(sed -n 2p $p.final_summary.txt | cut -d "$TAB" -f 3)
		echo -e "$p\t$IN" >> largest.txt
	else
		echo -e "$p\tAbs" >> largest.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_deccol.txt largest.txt Master_elfcol.txt
rm Master_deccol.txt
rm largest.txt

##adds the number of seqs in cluster 1 that are 80% matches to the largest seq to column 12
while read p;
	do 
	FILECHECK=$(ls -F | grep $p.final_summary.txt)
	if [ "$FILECHECK" != "" ]
	then
		IN=$(sed -n 2p $p.final_summary.txt | cut -d "$TAB" -f 5)
		echo -e "$p\t$IN" >> percent.txt
	else
		echo -e "$p\t0" >> percent.txt
	fi
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_elfcol.txt percent.txt Master_zwolfcol.txt
rm Master_elfcol.txt
rm percent.txt

##finds subdomains of the sample seq in domains file for each sample
while read p;
	do
	grep "$p" $SCRIPT/domains/vardb_domains.txt | cut -d "$TAB" -f 4 >> $p_grep.txt
	GSIZE=$(wc -l $p_grep.txt)
	BUILD=""
	##compares it to the subdomains of the largest seq in cluster 1
	while read q;
		do
		BUILD="$BUILD $q"
	done < $p_grep.txt
	echo -e "$p\t$BUILD" >> actual.txt
	ABSCHECK=true
	FILECHECK=$(ls -F | grep $p.final_summary.txt)
	if [ "$FILECHECK" != "" ]
	then
		IN=$(sed -n 2p $p.final_summary.txt | cut -d "$TAB" -f 7)
		echo -e "$p\t$IN" >> predict.txt
	else
		IN="Abs" 
		echo -e "$p\t$IN" >> predict.txt
		ABSCHECK=false
	fi
	if [ $ABSCHECK = true ]
	##if they match yes is written in column 13, no if they do not
	then
		if [ "$BUILD" = "$IN" ]
			then 
			echo -e "$p\tYes" >> True_match.txt
			else 
			echo -e "$p\tNo" >> True_match.txt
		fi
	else
		echo -e "$p\tAbs" >> True_match.txt
	fi
##NTS and ATS domains are removed from both subdomain structures and compared again
	START=$(echo $BUILD | grep -Eo 'NTS' | wc -l)
	FCUT=$((1 + $START))
	SDCOUNT=$(echo $BUILD | wc -w)
	END=$(echo $BUILD | grep -Eo 'ATS' | wc -l)
	BCUT=$(($SDCOUNT - $END))
	EBUILD=$(echo $BUILD | cut -d ' ' -f $FCUT-$BCUT)

	START=$(echo $IN | grep -Eo 'NTS' | wc -l)
	FCUT=$((1 + $START))
	SDCOUNT=$(echo $IN | wc -w)
	END=$(echo $IN | grep -Eo 'ATS' | wc -l)
	BCUT=$(($SDCOUNT - $END))
	EIN=$(echo $IN | cut -d ' ' -f $FCUT-$BCUT)
	if [ $ABSCHECK = true ]
	then
##whether they match or not is stored in column 14
		if [ "$EBUILD" = "$EIN" ]
		then
		echo -e "$p\tYes" >> Filt_match.txt
		else
		echo -e "$p\tNo" >> Filt_match.txt
		fi
	else
		echo -e "$p\tAbs" >> Filt_match.txt
	fi
	rm $p_grep.txt
done < $DIR/name.txt

python $SCRIPT/scripts/append_column.py Master_zwolfcol.txt True_match.txt Master_dreizcol.txt
rm Master_zwolfcol.txt
rm True_match.txt

python $SCRIPT/scripts/append_column.py Master_dreizcol.txt Filt_match.txt Master_vierz.txt
rm Master_dreizcol.txt
rm Filt_match.txt

##predicted subdomain structure added to column 15
python $SCRIPT/scripts/append_column.py Master_vierz.txt predict.txt Master_funf.txt
rm Master_vierz.txt
rm predict.txt

##actual subdomain structure added to column 16
python $SCRIPT/scripts/append_column.py Master_funf.txt actual.txt Master_table.txt
rm Master_funf.txt
rm actual.txt

##column headers added to copy of master table
echo -e "ID\tDB_unfiltered_hits\tDB_filtered_hits\tSelf_unfiltered_hits\tSelf_filtered_hits\tNum_of_clusters\tNum_of_unfiltered_links\tNum_of_links\tSample_match\tClust1_match\tClust1_Size\tClust1_largest\t80%_matches\tDomain_match\tNo_terminal_match\tPredicted_subdomains\tActual_subdomains" > $DIR/Master_table_header.txt
cat Master_table.txt >> $DIR/Master_table_header.txt
mv Master_table.txt $DIR/Master_table.txt
rm $DIR/name.txt
cd $RETURN
