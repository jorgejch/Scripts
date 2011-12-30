#!/usr/bin/perl

use strict;
use warnings;
use File::Tail;

########################################################################################################
#This simple script uses the File::Tail module to monitor a log file. When an string, signaling the end
#of the job, is matched on the log file, it then calls the 'action' subroutine. This subroutine will
#then execute the next job. It can also feed a new log name to be tailed. Some customizations may be
#required on the action subroutine.
#It also is required that the File::Tail module be installed.
######################################################################################################## 
#########################Basic necessary variables for execution########################################
my $targetString = "Normal termination of Gaussian"; #The target string that signals the end of the job.
my $logPath ="";                                     #The path to the jobs output file. Can be defined
                                                     #in the 'action' subroutine.
my $logSuffix=log;                                   #The suffix of your log files (ex: 'out', 'log').
my $maxCheckInterval = 300; #seconds                 #The maximum time to wait between file checks.                   
########################################################################################################
#####################Variables of the action subroutine#################################################
    #The command array receives the list of commands to execute on the shell.
    my @command= ("nohup g03 imn_gaussian_am1_opt.com &",
                  "nohup g03 imn_gaussian_DFT_6-31dp_opt.com &",
		  "nohup g03 imn_gaussian_6-31dp_opt.com &");
    my $i=0; #Command iterator.  
########################################################################################################
    action(0);

sub createLogTail {
    my $file = File::Tail->new(name=>$logPath,maxinterval=>$maxCheckInterval);

    while (defined(my $line=$file->read)){

#	print $line; ###debug
	
        if ($line =~ /$targetString/){
	    print "End of job number $i.\n";

	    $i++;
	    action($i);

	    last;
        }
    }
}
sub action {
    
    if ((@command >= $i)&& (!system($command[$_[0]]))) {
        print "Command '$command[$_[0]]' executed.\n";

	#The three lines below extracts the log name from the system command that was executed.	
	$command[$_[0]] =~ /(\S+)\.\w+/;
	$logPath="$1.$logSuffix";
	print "Log file title:'$logPath'\n";
	    
	createLogTail();
    }elseif (@command < $i){

	print "End of batch.\n"
    }
}
