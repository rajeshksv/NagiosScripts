#!/usr/bin/perl
use strict;
use Getopt::Long;

my $i = 0;
my $pid;
my @mount;
my $mount;
my $buffer = " ";
my @cols;
my $new_mount;
my $percent;
my $c   = 0;
my $w   = 0;
#my $x   = '';
my @x;
my $ret = 0;



$pid = fork();    
if ( $pid == 0 )
{
    exec("df -h | grep -v Filesystem > checkdisk.txt");   #forks a chlid for df -h command
}
else
{
    eval {
        local $SIG{ALRM} = sub { kill 9, $pid; die "TIMEOUT!" };  # kills the child after 5 secs
        alarm 5;
        waitpid( $pid, 0 );
        alarm 0;
    };

    open my $file, "<checkdisk.txt" or "die cannot open file"; 
    @mount = <$file>;                 #o/p of df-h in the file  is put into an array
    close($file);
    GetOptions(
        "x=s" => \@x,     #filesystems excluding the check
        "c=i" => \$c,     #filesystems critical check value
        "w=i" => \$w      #filesystems warning check value
    );
    if ( $c == 0 || $w == 0 )
    {
        usage();
        exit();
    }
    #Supporting globbing. Eg: /grid/# will now exclude all of /grid/1, /grid/2, etc
    @x = map {s/#/.*/;$_} @x;
    foreach $mount (@mount)  #processing line by line
    {
        $buffer = $mount . $buffer;    #concatinates if the filesystem and the diskusage are on different lines
        @cols = split /\s+/, $mount;   #line is put into an array with separated by space
        next if ( $#cols < 5 );        #if number of columns in a line is less than 5, process the next line in @mount array
        $new_mount = $cols[-1];        #will contain value of mount point
        $percent   = $cols[-2];        #will contain value of used percentage
        $percent =~ s/^(\d+)%/$1/;     #will remove "%" from the numerical value
         
	#print "\n x is @x";
	my $stat = grep{ $new_mount =~ /^$_$/ } @x;
	if($stat == 1)
	{
	next;
	}
        elsif ( $percent >= $c ) #checks if the percentage value is critical if critical returns exit status 2
        {
            print "$new_mount is critical $percent\n";
            $ret = 2;
        }
        elsif ( $percent >= $w && $percent < $c )  #checks if the percentage value is warning if warning returns exit status 1
        {
             print "$new_mount is warning $percent\n";
            $ret = 1 unless ( $ret == 2 );
        }
        else                                      #checks if the percentage value is normal
        {
             #print "$new_mount is okay\n";     
        }
    }
    $buffer = " ";                                #clears the buffer value after every loop
}
print "OK" if ($ret == 0);
print "WARNING" if($ret == 1);
exit $ret;

sub usage                                         #function which describes the usage
{
    print <<ENDOF
USAGE ./disk_check -c [value] -w [value] -x [value]
-c = Critical used value(compulsory)
-w = Warning used value(compulsory)
-x = Excluded Mount(optional) 
ENDOF
}

