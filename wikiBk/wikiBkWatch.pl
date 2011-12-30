#! /usr/bin/perl

#########################################################################################
# This scrit is a mediawiki bot, written to inform users of the status of a wiki's    #
# backup.										#
# Written by: Jorge Haddad								#
# Contact: jorgejch@gmail.com								#
# Last review date: 03/21/2009								#
#########################################################################################

use warnings;
use strict;
use CMS::MediaWiki;

#Creates and instantiates the CMS::Mediawiki bot, pointing to 'localhost'
my $mw = CMS::MediaWiki->new(
			host=>'localhost',
			path=>'mediawiki',
			debug=>1
			);

#Logs in the wiki using the Bot username and password, and calls the editing func.
if ($mw->login(user => 'Bot', pass => ',bot,')) {
	print STDERR "Could not login\n";
	exit;
}
else {
	edit();
}

sub edit {
#This funtion edits the wiki's "wiki_bk_info" page with the date of the last
#backup and the number of backups kept in memory.
  
	my @bkInfo = bkInfo(); #
 
	my $rc = $mw->editPage(
			title   => 'Wiki_bk_info' ,
			section => '2' , #  2 means edit second section etc.
		                          # '' = no section means edit the full page
			text    =>
			"== Info ==\n".
			"  Last successful backup: ".$bkInfo[0]."\n".
			"  Number of backups: ".($bkInfo[1]/3)."\n"
	);
}	
sub bkInfo{
#This function counts the number of backups on the "/root/backup/wiki" directory
#and figures out the lastest one, returning both in an array.
 
	opendir DH, "/root/backup/wiki";

	my $file;
	my $date = 0;
	my $prevDate;
	my $i;

	
	foreach $file (readdir DH){
		if ($file =~ /(\d{8})/){
			$prevDate = $1;
			$date = $prevDate if ($prevDate > $date);
			$i++;
		}
	}

	closedir DH;
	return ($date, $i);
}
