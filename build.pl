#!/cygdrive/c/Perl64/bin/perl

use strict;
use Cwd;
use File::Path;

print "Starting the script\n";
my $branch = $ARGV[0];
print "The branch is '" . $branch . "'\n";
unless ($branch) {
	print "usage: build.pl branch moduleName(optional)\n";
	exit(1);
}

my $buildWhat = $ARGV[1];
if(!defined $buildWhat){
	$buildWhat = "all";
}

if( (lc $buildWhat ne "import") && 
    (lc $buildWhat ne "migration") &&
	(lc $buildWhat ne "app") &&
	(lc $buildWhat ne "all")){
	print "invalid build module name, should be one of these 'import, migration, app, all' \n";
	exit(1);
}
	
if( (lc $buildWhat eq "app") ||
	(lc $buildWhat eq "all")){
	print "Build will include app\n";
}
else{
print "Build will include '" . $buildWhat . "' module only\n";
}

my $basesrcpath = $ENV{"SOURCEPATH"};
my $logdir = $ENV{"LOGPATH"};
my $src = "$basesrcpath";

print "The SOURCEPATH is '" . $basesrcpath . "'\n";
print "The LOGPATH is '" . $logdir . "'\n";
print "The src is '" . $src . "'\n";

if (-f "$src\\.lock") {
	print "Error: Build in progress\n";
	exit(1);
}


my $oldout;
my $olderr;

my $format = "%02d/%02d/%d %02d:%02d:%02d";
my $start = time();

my @d = localtime();
my $date = sprintf("%d%02d%02d%02d%02d%02d", $d[5] + 1900, $d[4] + 1, $d[3], $d[2], $d[1], $d[0]);

sub doCmd {
	my $cmdLine = shift(@_);
	print "$cmdLine\n";
	return system($cmdLine);
}

sub end($) {
	my $err = shift(@_);
	my @d = localtime();
	my $date = sprintf($format, $d[4] + 1, $d[3], $d[5] + 1900, $d[2], $d[1],
		$d[0]);
	my $time = sprintf("%.2f", (time() - $start) / 60);

	unlink("$src\\.lock");
    if ($err) {
		print "Build failed: $err\n";
	}
	print "Build $branch ended $date: $time minutes\n";
	open(STDOUT, ">&", $oldout);
	open(STDERR, ">&", $olderr);
	print "Build $branch ended $date: $time minutes\n";
	exit($err ? 1 : 0);
}

$date = sprintf($format, $d[4] + 1, $d[3], $d[5] + 1900, $d[2], $d[1], $d[0]);
unlink(glob("$logdir\\$branch*"));

# redirect stdio and disable buffering
open($oldout, ">&STDOUT");
open($olderr, ">&STDERR");
open(STDOUT, '>', "$logdir\\$branch-build.log");
open(STDERR, ">&STDOUT");
select STDOUT; $| = 1;
select STDERR; $| = 1;

print "Build $branch started $date\n";

open(LOCK, ">$src\\.lock");
close(LOCK);

mkdir($logdir);

if (doCmd("call $src\\winbuild.pl $branch $buildWhat")) {
	end("winbuild failed");
}
end(0);
