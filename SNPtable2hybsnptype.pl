#!/bin/perl
use warnings;
use strict;
#This script prints out each site where the parents are fixed differences, and says if the allele is parent 1, parent 2 or unique
#Requires parents to have 5 individuals sampled.
my $samplefile = $ARGV[0];
my %printlist;
my %specieslist;
open SAMPLEFILE, $samplefile;
while(<SAMPLEFILE>){
	chomp;
  	my @a = split(/\t/,$_);
	$printlist{$a[0]}++;
  	$specieslist{$a[0]} = $a[1]; #should have P1, P2 and any other name for hybrids
}
close SAMPLEFILE;

my $counter;
my %samplelist;
my @good_number_list;
my %good_number_hash;
my %species;
my $max_count = 20;
while(<STDIN>){
  	$counter++;
	chomp;
	my $line = "$_";
	my @a = split(/\t/,$line);
 	if ($. == 1){
    		foreach my $i (2..$#a){
      			$samplelist{$i} = $a[$i];
      			if ($specieslist{$a[$i]}){
        			$species{$i} = $specieslist{$a[$i]};
        			push(@good_number_list, $i);
				$good_number_hash{$i}++;
      			}
    		}
    		next;
  	}
	unless ($a[3]){
		next;
	}
  	my $pos = $a[1];
	my $chrom = $a[0];
 	my %P1alleles;
  	my %P2alleles;
  	my $P1count = 0;
  	my $P2count = 0;
  	if (($counter % 100000)== 0){
		print STDERR "Processing $chrom $pos...\n";
	}
  	foreach my $i (keys %good_number_hash){ #Load up parental alleles
    		if ($a[$i] ne "NN"){
      			if ($species{$i} eq "P1"){
			        $P1count++;
		      	}elsif($species{$i} eq "P2"){
			        $P2count++;
		      	}
    		}
  	}
  	unless(($P1count >=5) and ($P2count >= 5)){
    		next;
  	}
	my $min_count; #Samples are subset down to the lowest sample size of either parent
	if ($P1count < $P2count){
		$min_count = $P1count;
	}else{
		$min_count = $P2count;
	}
	if ($min_count > $max_count){
		$min_count = $max_count;
	}
	my $P1count2 = 0;
	my $P2count2 = 0;
	my %alleles;
        foreach my $j (keys %good_number_hash){ #Load up parental alleles
                if ($a[$j] ne "NN"){ #if it doesn't count itself
                        if ((($species{$j} eq "P1") and ($P1count2 < $min_count)) or (($species{$j} eq "P2") and ($P2count2 < $min_count))){
                                if ($species{$j} eq "P1"){
                                        $P1count2++;
                                }else{
                                       	$P2count2++;
                                }
                               	my @parentalbases = split(//,$a[$j]);
				$alleles{$species{$j}}{$parentalbases[0]}++;
				$alleles{$species{$j}}{$parentalbases[1]}++;
                        }
                }
	}
	#Check if they are fixed differences. 
	foreach my $P1allele (keys %{$alleles{"P1"}}){
		foreach my $P2allele (keys %{$alleles{"P2"}}){
			if ($P1allele eq $P2allele){
				goto NEXTLINE;
			}
		}
	}
	#Check hybrid alleles against parental ones
	foreach my $i (keys %good_number_hash){
		if (($a[$i] ne "NN") and ($species{$i} ne "P1") and ($species{$i} ne "P2")){
			my @bases = split(//,$a[$i]);
			my $P1type;
			my $P2type;
			my $uniquetype;
			foreach my $n (0..1){
				if ($alleles{"P1"}{$bases[$n]}){
					$P1type++;
				}elsif ($alleles{"P2"}{$bases[$n]}){
					$P2type++;
				}else{
					$uniquetype++;
				}
			}
			if ($P1type){
                                print "\n$chrom\t$pos\t$samplelist{$i}\t$species{$i}\t1"; #it's only in parent 1
                        }
			if($P2type){
                                print "\n$chrom\t$pos\t$samplelist{$i}\t$species{$i}\t2"; #It's only in parent 2
                        }
			if($uniquetype){
                                print "\n$chrom\t$pos\t$samplelist{$i}\t$species{$i}\t0"; #It's not in the parents
			}
		}
	}
	NEXTLINE:
}

