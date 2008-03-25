#!/usr/bin/perl

# On each new line from STDIN, we change the value.

$var=2371.2;
$ref=\$var;
for $run (1 .. 10)
{
	$$ref += 113/$run;
	print "========= NEW VALUE: $var\n";
	scalar(<STDIN>);
}
exit;

