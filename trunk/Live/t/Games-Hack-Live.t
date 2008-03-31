#!/usr/bin/perl
#########################

use Test::More;
use Expect;

#########################
@patients=("double", "long");

# It seems that ok() cannot be used in a loop.
# So I had to change the "ok" in the middle to "fail() if".
plan "tests" => 1+@patients;

sub Diag {
#diag(@_);
} 

$Expect::Log_Stdout=0;

#########################
ok(1, "start");

our $current_val;

$slave_getvalue= [ qr(^={5,} NEW VALUE: (\S+)), 
	sub { 
		my($self)=@_;
		$current_val=($self->matchlist())[0]; 
	} 
];


for $patient (@patients)
{
	Diag("Going for $patient");

	$slave=new Expect;
	$slave->raw_pty(1);
	$slave->spawn("t/test-$patient.pl", ())
		or die "Cannot spawn test-$patient.pl";

	$client = new Expect;
	$client->raw_pty(1);
	$client->spawn("hack-live -p" . $slave->pid, ())
		or die "Cannot spawn Games::Hack::Live: $!\n";

# Testing here doesn't work. It seems that perl doesn't keep the scalar at 
# the same memory location, but moves it around. 
# Strangely that works if the perl script is run separately - does the 
# Test:: framework something like eval()?

	$client->print("\n\n");
	$client->expect(4, [ qr(^---), ] );



	$loop_max=5;
# Take a few values, then try to inhibit changes.
	for (1 .. $loop_max)
	{
		$current_val=0;
		$slave->expect(1, $slave_getvalue);

		die "unidentifiable output\n" unless $current_val;

		Diag("got current value as $current_val\n");
		$client->print(
				$current_val =~ m#\.# ?
				"find ($patient) ". ($current_val-1) ." ". ($current_val+1) ."\n" :
				"find ($patient) $current_val\n");
		$client->expect(1, [ qr(--->), sub { } ], );
		$last=$client->before;
#		print STDERR $last;
		$last =~ /Most wanted:\s+(.*)/;
#		print STDERR "==== has $current_val: $1\n";

		$slave->print("\n");
	}


	$last=$client->before;
	($adr, $count)=($last =~ /Most wanted:\s+(\w+)\((\d+)\)/);
	Diag("got address $adr, with $count matches.");
	fail("No address found?") unless $adr;
# we allow a single bad value.
	fail("Not enough matches found?") unless ($count >= $loop_max-1);


	Diag("Trying to kill writes.\n");

	$client->clear_accum;
	$client->print("killwrites $adr\n");
	$client->expect(1, [ qr(--->), sub { } ], );
	$slave->print("\n");
	$slave->print("\n");

	$slave->clear_accum;
	$slave->print("\n");
	$slave->expect(1, $slave_getvalue);
	$old=$current_val;
	$slave->print("\n");
	$slave->expect(1, $slave_getvalue);
	$new=$current_val;

	Diag("old was $old, new is $new");
	ok($old == $new ,"changed value?");

	$client->print("kill\n\n");
	$client->hard_close;
	$slave->hard_close;

	Diag("$patient done\n");
}

exit;

