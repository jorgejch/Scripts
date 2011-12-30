#!/usr/bin/perl

use strict;
use warnings;

my $logfile = $ARGV[0];
open (LOG,$logfile) or die "Usage: view_charges.pl <gaussian log file>.\n";

my @charges;
my @position;

while (<LOG>){

	if (/Molden generated mol2/){
	
		my $i=1; #Counter for Atoms.

		while (<LOG>){
			
			if (/(\w{1,2})\s{17,21}(-?[0-9.]{6,7})\s{2,}(-?[0-9.]{6,7})\s{2,}(-?[0-9.]{6,7})/){
					push (@position,{"atomNum"=>$i++,
						         "atom"=>$1,
					        	 "xPos"=>$2,
						 	 "yPos"=>$3,
							 "zPos"=>$4,});

			}elsif(/Input orientation:/){
				last;
			}
		}
	}
	if (/Charges from ESP fit,/){
		while (<LOG>){
			if (/(\d{1,3})\s{2}(\w{1,2})\s{1,4}(-?[0-9.]{8})/){

				push (@charges,{"atomNum"=>$1,
					        "atom"=>$2,
             		                        "charge"=>$3});

			}elsif(/Electrostatic Properties/){
				
				last;
			}
		}
		last;
	}

}
close (LOG);

####Writing PDB######
print ("Name of the desired pdb file to output:\n");
my $pdbName = <STDIN>;
chomp($pdbName);
open (PDB,">",$pdbName);

for (my $i=0;$i<@charges;$i++){
       format PDB =
ATOM  @####  @<<@>>>  @###    @###.###@###.###@###.###      @#.###
$position[$i]{"atomNum"},$position[$i]{"atom"},"1",1,$position[$i]{"xPos"},$position[$i]{"yPos"},$position[$i]{"zPos"},$charges[$i]{"charge"}
.
	write PDB;
}
close (PDB);
