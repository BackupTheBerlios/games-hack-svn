#!/usr/bin/perl

use integer;

# On each new line from STDIN, we change the value.

$var=526543;
$ref=\$var;
do
{
	$$ref += 113+ ++$run;
	print "========= NEW VALUE: $var\n";
} until (<STDIN> =~ /quit/);
exit;

