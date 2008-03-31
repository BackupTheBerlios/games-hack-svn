#!/usr/bin/perl

# On each new line from STDIN, we change the value.

$var= 2371.2+(3.14+2.71)*$$;
$const=0.42;
$ref=\$var;
while (<STDIN>)
{
	$$ref += 113/ ++$run;
	# If we'd print the value directly, it would be on the stack and in some 
	# buffers, too. So we print an expression that has to evaluated by the 
	# caller.
	printf "========= NEW VALUE: %f*%f  *0x%X\n",
				 $var/$const, $const,
				 unpack("l", pack("P", $var));
}
exit;

