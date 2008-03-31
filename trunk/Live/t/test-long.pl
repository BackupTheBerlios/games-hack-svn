#!/usr/bin/perl

use integer;

# On each new line from STDIN, we change the value.

$var=526543+$$*7;
$ref=\$var;
while (<STDIN>)
{
	$$ref += 113+ ++$run;
	print "========= NEW VALUE: $var\n";
}
exit;

