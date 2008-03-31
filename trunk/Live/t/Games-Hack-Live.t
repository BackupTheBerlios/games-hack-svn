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



	$loop_min=5;
	$loop_max=17;
# Take a few values, then try to inhibit changes.
	for $loop (1 .. $loop_max)
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
		($wanted)=($last =~ /Most wanted:\s+(\w.*)/);
		@matches=grep($_ !~ /^(0x0+)?0$/,$wanted =~ /(\w+)\((\d+)\)/g);
#		print STDERR "$loop: $wanted\n==== has $current_val: ", 
#		join(" ", @matches),"\n", 0+@matches, $matches[1] > $matches[3],"\n";

# Stop testing if there's only a single match, or a single best match.
		last if ($loop > $loop_min) && 
			(@matches == 2 ||
			 $matches[1] > $matches[3]);

		$slave->print("\n");
	}


	($adr, $count)=@matches;
	$last=$client->before;
	Diag("got address $adr, with $count matches.");
	fail("No address found?") unless $adr;
# we allow a single bad value.
	fail("Not enough matches found?") unless ($count >= $loop-1);


	Diag("Trying to kill writes.\n");

	$client->print("killwrites $adr\n");
	$client->clear_accum;
	$client->expect(1, [ qr(--->), sub { } ], );
	$slave->print("\n");
	$slave->clear_accum;
	$slave->print("\n");
	$slave->expect(1, $slave_getvalue);

	$slave->print("\n");
	$slave->clear_accum;
	$slave->expect(1, $slave_getvalue);
	$old=$current_val;
	$slave->print("\n");
	$slave->expect(1, $slave_getvalue);
	$new=$current_val;

	Diag("old was $old, new is $new");
	ok($old == $new ,"changed value ($old == $new)?");

	$slave->print("quit\n");
	$client->print("kill\n\n");
	$client->hard_close;
	$slave->hard_close;

	Diag("$patient done\n");
}

exit;

