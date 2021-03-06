#!/usr/bin/perl

use warnings;
use strict;
use lib '/home/owens/bin/pop_gen/'; #For GObox server
my %t;
$t{"N"} = "NN";
$t{"A"} = "AA";
$t{"T"} = "TT";
$t{"G"} = "GG";
$t{"C"} = "CC";
$t{"W"} = "TA";
$t{"R"} = "AG";
$t{"M"} = "AC";
$t{"S"} = "CG";
$t{"K"} = "TG";
$t{"Y"} = "CT";

my %samples;
my @Good_samples;
my %Anc;
my %AncCount;
my %TotalSites;
my %pop;
my %Genotype;

my %samplepop;

my %poplist;
my $Npops = 2;
my $BiCount = 0;
my $TriCount= 0;
my $QuadCount = 0;
my $SingleTri =0;

unless (@ARGV == 3) {die;}
my $in = $ARGV[0]; #SNP table
my $pop = $ARGV[1]; #List of samples linked to population 
my $groups = $ARGV[2]; #List of all populations with populations selected (1 and 2)
require "countbadcolumns.pl";
my ($iupac_coding, $badcolumns) = count_bad_columns($in);
$. = 0;

open POP, $pop;
while (<POP>){
	chomp;
	my @a = split (/\t/,$_);	
	$pop{$a[0]}=$a[1];
	$poplist{$a[1]}++;
}
close POP;

my %group;
open GROUP, $groups;
while (<GROUP>){
        chomp;
        my @a = split (/\t/,$_);
        $group{$a[0]} = $a[1];
}
close GROUP;


my %samplegroup;
open IN, $in;
while (<IN>){
	chomp;
	my @a = split (/\t/,$_);
  	if ($. == 1){
  		foreach my $i ($badcolumns..$#a){ #Get sample names for each column
        		if ($pop{$a[$i]}){
        			$samplepop{$i} = $pop{$a[$i]};
				if ($group{$pop{$a[$i]}}){
					$samplegroup{$i} = $group{$pop{$a[$i]}};
				}
        		}
        	}
        	print $a[0]."-"."$a[1]\t$a[0]\t$a[1]";
		print "\tN1\tHexp";
	}
	else{
		next if /^\s*$/;
		print "\n";
		print $a[0]."-"."$a[1]\t$a[0]";
		foreach my $i (1..($badcolumns-1)){
			print "\t$a[$i]";
		}
		my %BC;
		my %BS;
		my %total_alleles;
		foreach my $i ($badcolumns..$#a){
			if ($samplegroup{$i}){
				$BC{"total"}{"total"}++;
				if ($iupac_coding eq "TRUE"){
						$a[$i] = $t{$a[$i]};
				}
				unless (($a[$i] eq "NN")or($a[$i] eq "XX")){
					my @bases = split(//, $a[$i]);
					$total_alleles{$bases[0]}++;
					$total_alleles{$bases[1]}++;
				
					$BC{"total"}{$bases[0]}++;
		        		$BC{"total"}{$bases[1]}++;
					$BC{$samplegroup{$i}}{$bases[0]}++;
		 			$BC{$samplegroup{$i}}{$bases[1]}++;

					$BC{"total"}{"Calls"}++;
					$BC{$samplegroup{$i}}{"Calls"}++;
					
					if($bases[0] ne $bases[1]){
						$BC{"total"}{"Het"}++;
						$BC{$samplegroup{$i}}{"Het"}++;
					}
				}
			} 
		}

		my $pAll;
		my $qAll;
		my $HeAll;
		my $HoAll;
		my $CallRate;
		my $p1;
		my $q1;
		my $p2;
		my $q2;
		my $Ho1;
		my $Ho2;
		my $He1 ;
		my $He2;
		my $dxy;
		my $HsBar;
		my $H_bar;
		my $n_bar;
		my $n_1;
		my $n_2;
		my $n_total;
		my $sigma_squared;
		my $n_c;
		my $WC_a;
		my $WC_b;
		my $WC_c;
		my $WC_denom;
		my $WC_fst;
		my $pi;
		my $freq_dif;
		

		unless ($BC{"total"}{"Calls"}){
			$BC{"total"}{"Calls"} = 0;
		}
		
		$CallRate = $BC{"total"}{"Calls"}/ $BC{"total"}{"total"};

		#print "\t".keys %total_alleles;
		unless ($BC{"1"}{"Calls"}){
                        $pAll = "NA";
                        $qAll = "NA";
                        $HeAll = "NA";
                        $HoAll = "NA";
                        $p1 = "NA";
                        $q1 = "NA";
                        $p2 = "NA";
                        $q2 = "NA";
                        $Ho1 = "NA";
                        $Ho2 = "NA";
                        $He1 = "NA";
                        $He2 = "NA";
                        $dxy = "NA"; ##Need to fix
                        $HsBar = "NA";
                        $n_total = $BC{"total"}{"Calls"};
                        $sigma_squared = "NA";
                        $H_bar = "NA";
                        if ($BC{"1"}{"Calls"}){
                                $n_1 = $BC{"1"}{"Calls"};
                        }else{
                                $n_1 = 0;
                        }
                        #Sample size for population 2
                        if ($BC{"2"}{"Calls"}){
                                $n_2 = $BC{"2"}{"Calls"};
                        }else{
                                $n_2 = 0;
                        }
			$n_bar = "NA";
                        $WC_a = "NA"; ##
                        $WC_b = "NA"; ##
                        $WC_c = "NA"; ##
                        $WC_denom = "NA"; ##
                        $WC_fst = "NA"; ##
                        $pi = "NA"; ###Need to fix
                        $freq_dif = "NA";		
		}elsif (keys %total_alleles == 2){
		
			#Sort bases so p is the major allele and q is the minor allele
			my @bases = sort { $total_alleles{$a} <=> $total_alleles{$b} } keys %total_alleles ;
			#Major allele
			my $b1 = $bases[1];
			#Minor allele
			my $b2 = $bases[0];
			
			#Total number of samples
			$n_total = $BC{"total"}{"Calls"};
			#Major allele frequency in all samples
			$pAll = $BC{"total"}{$b1}/($BC{"total"}{"Calls"}*2);
			#Minor allele frequency in all samples
			$qAll = $BC{"total"}{$b2}/($BC{"total"}{"Calls"}*2);

			#Heterozygosity expected in all samples
			$HeAll = 2*($pAll * $qAll);

			#Heterozygosity observed in all samples
			if ($BC{"total"}{"Het"}){
				$HoAll = $BC{"total"}{"Het"}/($BC{"total"}{"Calls"}*2);
			}else{
				$HoAll = 0;
			}
			#Allele frequency of each allele in each population
			if ($BC{"1"}{$b1}){
				$p1 = $BC{"1"}{$b1}/($BC{"1"}{"Calls"}*2);
			}else{
				$p1 = 0;
			}
			if ($BC{"1"}{$b2}){
				$q1 = $BC{"1"}{$b2}/($BC{"1"}{"Calls"}*2);
			}else{
				$q1 = 0;
			}

			#Heterozygosity observed in each population
			if ($BC{"1"}{"Het"}){
				$Ho1 = $BC{"1"}{"Het"}/$BC{"1"}{"Calls"}
			}else{
				$Ho1 = 0;
			}

			#Amount of pairwise difference between population

			#Heterozygosity expected
			$He1 = 2*($p1 * $q1);


			#Sample size for population 1
			if ($BC{"1"}{"Calls"}){
				$n_1 = $BC{"1"}{"Calls"};
			}else{
				$n_1 = 0;
			}
		}elsif (keys %total_alleles eq 1){
			$pAll = 1;
			$qAll = 0;
			$HeAll = 0;
			$HoAll = 0;
			$p1 = 1;
			$q1 = 0;
			$p2 = 1;
			$q2 = 0;
			$Ho1 = 0;
			$Ho2 = 0;
			$He1 = 0;
			$He2 = 0;
			$dxy = 0;
			$HsBar = "NA";
			$sigma_squared = "NA";
			$H_bar = "0";
			#Average sample size for populations
			$n_bar = ($BC{"total"}{"Calls"} / 2);
			#Sample size for population 1
			if ($BC{"1"}{"Calls"}){
				$n_1 = $BC{"1"}{"Calls"};
			}else{
				$n_1 = 0;
			}
			if ($BC{"2"}{"Calls"}){
				$n_2 = $BC{"2"}{"Calls"};
			}else{
				$n_2 = 0;
			}
			#Total number of samples
			$n_total = $BC{"total"}{"Calls"};
			$WC_a = "0";
			$WC_b = "0";
			$WC_c = "0";
			$WC_denom = "0";
			$WC_fst = "0";
			$freq_dif = "0";
			$pi = "0";
		}
		elsif (keys %total_alleles eq 3){ #Need to account for three alleles in tri-allelic sites.
                        $pAll = "NA";
                        $qAll = "NA";
                        $HeAll = "NA";
                        $HoAll = "NA";
                        $p1 = "NA";
                        $q1 = "NA";
                        $p2 = "NA";
                        $q2 = "NA";
                        $Ho1 = "NA";
                        $Ho2 = "NA";
                        $He1 = "NA";
                        $He2 = "NA";
			$dxy = "NA"; ##Need to fix
			$HsBar = "NA";
			$n_total = $BC{"total"}{"Calls"}; 
			$sigma_squared = "NA"; 
			$H_bar = "NA";
			$n_1 = "NA";
			$n_2 = "NA";
			$n_bar = "NA";
			$WC_a = "NA"; ##
			$WC_b = "NA"; ##
			$WC_c = "NA"; ##
			$WC_denom = "NA"; ##
			$WC_fst = "NA"; ##
			$pi = "NA"; ###Need to fix
			$freq_dif = "NA";
		}elsif ((keys %total_alleles eq 4) or (keys %total_alleles eq 0)){ #If there are four alleles
			$pAll = "NA";
			$qAll = "NA";
			$HeAll = "NA";
			$HoAll = "NA";
			$p1 = "NA";
			$q1 = "NA";
			$p2 = "NA";
			$q2 = "NA";
			$Ho1 = "NA";
			$Ho2 = "NA";
			$He1 = "NA";
			$He2 = "NA";
			$dxy = "NA"; ##Need to fix
			$HsBar = "NA";
			$n_total = $BC{"total"}{"Calls"}; 
			$sigma_squared = "NA"; 
			$H_bar = "NA";
			$n_bar = "NA";
			$n_1 = "NA";
			$n_2 = "NA";
			$WC_a = "NA"; ##
			$WC_b = "NA"; ##
			$WC_c = "NA"; ##
			$WC_denom = "NA"; ##
			$WC_fst = "NA"; ##
			$pi = "NA"; ###Need to fix
			$freq_dif = "NA";
		}
		print "\t$n_1\t$He1";
	}
}
close IN;

