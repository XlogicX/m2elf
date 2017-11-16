#!/usr/bin/perl
#ELF construction based on reversing done by Ange Albertini from corkami.com (great infographic),
#http://man7.org/linux/man-pages/man5/elf.5.html, and just assembling stuff with nasm and comparing results.
#These files generated may not be 'proper,' but they seem execute pretty well.
use warnings;
use strict;
use Getopt::Long;
use Term::ANSIColor;

my ($in, $binary, $hex, $code);
my $out = "out";
my $temp_data;
my $memory_size = 0;
my $entry = 0;
my $writeover = 0;
my $help = 0;
my $interactive = 0;
my $flavor = "intel";
my $colorize = 0;

sub colorize($);

GetOptions('in=s' => \$in,
'out=s' => \$out,
'binary' => \$binary,
'mem=s' => \$memory_size,
'entry=s' => \$entry,
'writeover' => \$writeover,
'interactive' => \$interactive,
'flavor=s' => \$flavor,
'colorize' => \$colorize,
'help' => \$help);

if ($help eq 1){
	help();
}

if ($interactive eq 1){
	my $result;
	qx{which objdump 2>&1};
	if ($? > 0) {
		print "This system needs 'objdump' installed in order to run 'interactive' mode\n";
	} else {
		$code = '';
		$out = 'tmp';
		while (1) {
			print "m2elf > ";
			$code = <STDIN>;
            		next if ($code =~ /^$/);
			last if ($code =~ /(exit|q(?:uit)*)/i);
			convert();
			payload();
			$result = `objdump -M $flavor -d tmp`;
			$result =~ s/^.+?<>:\n(.+)\s\.\.\..+$/$1/s;
			if ($colorize) {
                		print colorize($result), "\n";
            		} else {
               			print "$result\n";
            		}
		}
		system('rm tmp')
	}
}

#--------------------------Code/Strings/Sections------------------------------------
if ($in) {
	
	$/ = undef;
	open IN, "$in" or die "Couldn't open $in, $!\n";
	$code = <IN>;
	$/ = "\n";

	if ($binary) {
	} else {
		convert();
	}
} else {
	$code = "\x90\x90\x90\x90\x90\x90\xb8\x01\x00\x00\x00\xcd\x80";
}

sub payload {

	#Fix padding of code; pad code to be divisible by 16 bytes
	$code .= "\x00" x (16 - (length($code) % 16)) if ((length($code) % 16) != 0);

	#Section Names
	my $shstrtab_name = "\x00\x2e\x73\x68\x73\x74\x72\x74\x61\x62\x00"; #null record followed by ".shstrtab"
	my $text_name = "\x2e\x74\x65\x78\x74\x00";							#".text"
	my $bss_name = '';													#Does not exist unless --mem is declared with a value
	my $section_names = '';												#just an init of our section names header
	if ($memory_size > 0) {															#If allocating memory
		$bss_name = "\x2e\x62\x73\x73\x00";											#".bss"
		$section_names = $shstrtab_name . $text_name . $bss_name . ("\x00" x 10);	#section names is null+.shstrtab+.text+.bss+10bytes_padding
	} else {																		#Otherwise, build without .bss
		$section_names = $shstrtab_name . $text_name . ("\x00" x 15);				#So null+.shstrtab+.text and pad 15 bytes
	}


	#Section Header Table
	#Null Section
	my $null = "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";

	#Text Section
	#name at offset 0b, type 01, flags 0x06 (allocated & executable), start at addr 0x8000060 / offset 0x60
	my $text = "\x0b\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\x60\x00\x00\x08\x60\x00\x00\x00";
	if ($memory_size > 0) {		#if we allocated memory, change the start at addr to 0x8000080 / offset 0x80
		$text = "\x0b\x00\x00\x00\x01\x00\x00\x00\x06\x00\x00\x00\x80\x00\x00\x08\x80\x00\x00\x00";
	}
	my $offset = printhex_32(length($code));		#get length of padded code and represent as intel-endian 4-byte structure
	#concatenate headers so far, possible different offset due to memory alloc, structured size, and pretty much null-pad out
	$text .= $offset . "\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00";

	#Section Names section, but I'll just call this Shitter Tab.
	my $shrtrtab = '';			#init
	my $bss_header = '';		#init
	my $sections = '';			#init
	if ($memory_size > 0) {		#if there's memory,
		#BSS Header now...
		$bss_header = "\x11\x00\x00\x00" . "\x08\x00\x00\x00" . "\x03\x00\x00\x00";	#name header starts at 0x11, type 8, flag 3
		$offset = printhex_32(100663296);	#0x06000000
		$bss_header .= $offset;				#add the start addr
		$offset = printhex_32(4096);		#offset 0x1000
		$bss_header .= $offset;				#add the offset
		$offset = printhex_32($memory_size);	#add intel-endian bytes for size of bss section
		#Finally, null pad this header out
		$bss_header .= $offset . "\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00";

		#Now to proceed with the Shitter Tab
		#name offset starts at 0x01, it's type 3 (string table), no flags (null), no addr
		$shrtrtab = "\x01\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
		$offset = printhex_32(128 + length($code));											#intel-endian offset + 0x80
		#size is always 0x19 bytes, then null-pad out
		$shrtrtab .= $offset . "\x19\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00";

		#Glue the .bss version of section header table together
		$sections = $null . $text . $bss_header . $shrtrtab;
	} else {
		#Without .bss, the shitter table has an offset of 0xa0
		$shrtrtab = "\x01\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xa0\x00\x00\x00\x19\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00";
		#Glue the non .bss version of the section header table together
		$sections = $null . $text . $shrtrtab;
	}


	#--------------------------Program Header Table setup------------------------------
	#This is all for the .text segment
	my $p_type = "\x01\x00\x00\x00";				#The segment should be loaded into memory
	my $p_offset = "\x00\x00\x00\x00";				#Offset where it should be read
	my $p_addr = "\x00\x00\x00\x08";				#Virtual address where it should be loaded
	my $p_paddr = "\x00\x00\x00\x08"; 				#Physical address where it should be loaded
	my $p_flags = "\x05\x00\x00\x00"; 				#Readable and eXecutable (by default)

	#If we LOVE self modifying code, put your hands up!
	if ($writeover eq 1) {
		$p_flags = "\x06\x00\x00\x00";
	}

	#Give a little extra mem for now, until I actually try and figure this out, but I don't care
	my $p_filesz = printhex_32(length($code) + 160);	#Size on file
	my $p_memsz = $p_filesz;							#Size in memory

	#Build the header up
	my $program_header_table = $p_type . $p_offset . $p_addr . $p_paddr . $p_filesz . $p_memsz . $p_flags . "\x00\x10\x00\x00";

	#If we want memeory, the below code builds up the .bss segment
	if ($memory_size > 0) {	
		#Similar headers as .text, but starts at 0x6000000, and flags are rwx by default on this one
		$program_header_table .= "\x01\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x06\x00\x10\x00\x06";
		$program_header_table .= printhex_32($memory_size) . printhex_32($memory_size);
		$program_header_table .= "\x06\x00\x00\x00\x00\x10\x00\x00";
	}	

	#--------------------------ELF Header setup---------------------------------------

	my $e_ident_EI_MAG = "\x7f\x45\x4c\x46";		#constant signature (ELF)
	my $e_ident_EI_CLASS_DATA = "\x01\x01";			#32 bits, Little-Endian
	my $e_ident_EI_VERSION = "\x01\x00\x00\x00";	#Always 1
	my $e_type = "\x02\x00"; 						#Executable
	my $e_machine = "\x03\x00";						#Intel 386 (and later)
	my $e_version = "\x01\x00\x00\x00"; 			#Always 1
	my $e_entry = "\x60\x00\x00\x08";				#Entry Point
	my $e_phoff = "\x40\x00\x00\x00";				#Program Headers' offset
	my $e_shoff = "\x00\x00\x00\x00";				#Section Header's offset, 0'd out for now, calculated later
	my $e_ehsize = "\x34\x00";						#ELF header's size
	my $e_phentsize = "\x20\x00";					#Size of a single Program Header
	my $e_phnum = "\x01\x00";						#Count of Program Headers
	my $e_shentsize = "\x28\x00";					#Size of a single Section Header (probably static)
	my $e_shnum = "\x03\x00";						#Count of Section Headers
	my $e_shstrndx = "\x02\x00";					#Index of the names' section in the table
	#A few values need changing if we allocate memory with .bss segment (offsets and stuff)
	if ($memory_size > 0) {
		$e_shnum = "\x04\x00";
		$e_shstrndx = "\x03\x00";
		$e_phnum = "\x02\x00";
		$e_entry = "\x80\x00\x00\x08";	
	}

	#Change entry point if user wants this, it is not a specific address; it's a number of bytes to add to the current entry offset
	if ($entry > 0) {
		$entry += 134217824;
		$e_entry = printhex_32($entry);
	}

	#Calculate e_shoff size (Section Header offset)
	$e_shoff = length($code . $section_names) + 96;	#section names + code + 96 bytes of fixed size ELF headers
	if ($memory_size > 0) {
		$e_shoff += 32;								#32 bytes of extra header info if we have .bss
	}
	$e_shoff = printhex_32($e_shoff);				#format this number to intel-endian 4-byte value

	#Build ELF Header
	my $ELF_header = $e_ident_EI_MAG . $e_ident_EI_CLASS_DATA . $e_ident_EI_VERSION . ("\x00" x 6) . $e_type . $e_machine . $e_version . 
	$e_entry . $e_phoff . $e_shoff . ("\x00" x 4) . $e_ehsize . $e_phentsize . $e_phnum . $e_shentsize . $e_shnum . $e_shstrndx . ("\x00" x 12);

	#-------------------------combine everything--------------------------------------
	my $output = $ELF_header . $program_header_table . $code . $section_names . $sections;

	#write all of this to our file
	open FILE, ">$out" or die "Couldn't open $out, $!\n";
	print FILE $output;		#send it out
	close FILE;
	chmod(0755, $out) or die "Couldn't change the permission to $out: $!";

}

payload();

#This sub takes an integer and converts it into it's 32-bit intel-endian form
sub printhex_32 {
	my $value = shift;	#get the value passed to it
	my $return;	#make a return variable
	$value = sprintf("%.8X\n", $value);	#get an "ASCII HEX" version of the value
	if ($value =~ /(.)(.)(.)(.)(.)(.)(.)(.)/) {	#parse out each character
		$return = pack("C*", map { $_ ? hex($_) :() } $7.$8) . pack("C*", map { $_ ? hex($_) :() } $5.$6) .
		pack("C*", map { $_ ? hex($_) :() } $3.$4) . pack("C*", map { $_ ? hex($_) :() } $1.$2);	#unpack it
	}
	return $return;	#return the hex data
}

sub convert {
	my $temp_code = '';
	$code =~ s/(.*)(#|\/\/|'|\-\-).*/$1/g;	#remove comments
	#Find 8-bit binary strings and convert to ascii-hex
	while ($code =~ /_([01]{8})[^01]/) {
		my $replacement = sprintf('%X', oct("0b$1"));
		if (length($replacement) == 1) {
			$replacement = "0" . $replacement;
		}
		$code =~ s/_[01]{8}([^01])/$replacement $1/;
	}
	$code =~ s/\s//g;						#remove spaces

	#Has pure ascii-hex, convert to binary data
	while ($code =~ /(..)/) { 		#Get the matching hex into $1
		$temp_code .= pack("C*", map { $_ ? hex($_) :() } $1);
		$code =~ s/^..//;
	}
	$code = $temp_code;
}

sub colorize($) {
    my $code = shift || return undef;
    my($addr, $opcode, $inst, $operands) = $code =~ m/^[\s\t]*(\d+)\:[\s\t]+((?:[\da-f]+\s)+)[\s\t]+([a-z]+)\s*(.*)$/gi;
    my($green, $yellow, $blue, $red, $reset) = (color('green'), color('yellow'), color('blue'), color('red'), color('reset'));
    
    return undef unless (defined $addr);
    $code =~ s/$addr/$green$addr$reset/;
    $code =~ s/$opcode/$yellow$opcode$reset/;
    $code =~ s/$inst/$blue$inst$reset/;
    if (defined $operands) {
        $operands =~ s/([\[\]\(\)+\-*\$])/\\$1/g;
        $code =~ s/$operands/$red$operands$reset/;
        $code =~ s/\\//g;
    }

    return $code;
}

sub help {
print "NAME\n";
print "\tm2elf - Machine Code to ELF wrapped executable binary\n\n";
print "SYNOPSIS\n";
print "\tm2elf.pl --in inputfile --out outputfile\n\n";
print "DESCRIPTION\n";
print "\tThis script takes ascii-hex, space delimited chunks of 8 1' and 0's, or a binary file as input and crafts an appropriate ELF header to make this machine code executable on Linux (32-bit).\n\n";
print "OPTIONS\n";
print "\t--in: specify your source file after this\n";
print "\t--out: specify the name you want your executable file to be\n";
print "\t--interactive: use interactive mode\n";
print "\t--binary: if your file is raw (binary file with unprintables; already machine code), then supply this option. This option is great for extractions from pcaps\n";
print "\t--mem: specify how many bytes of memory you want after this option, it will map starting at offset 0x06000000\n";
print "\t--entry: you can change the entry point. The default is 0x08000060. Whichever number you specify, will add that amount of bytes to the default offset. It will not shift the beginning of your code to that offset, however. For example, if you supply --entry 16, add 16 NOPs to the begginning of your original code and it will function as if you didn't add the --entry 16 and the NOPs\n";
print "\t--writeover: changes the r-x of the .text to rwx; now you can have self modifying codes\n";
print "\t--flavor: flavor of output, default is 'intel' syntax (man objdump for a list of syntax flavors)\n";
print "\t--colorize: colorize output\n\n";
print "EXAMPLES\n";
print "\tSOURCE:\n";
print "\tb8\t21 0a 00 00\t#moving '!\\n' into eax\n";
print "\ta3\t0c 10 00 06\t#moving eax into first memory location\n";
print "\tb8\t6f 72 6c 64\t#moving 'orld' into eax\n";
print "\ta3\t08 10 00 06\t#moving eax into next memory location\n";
print "\tb8\t6f 2c 20 57\t#moving 'o, W' into eax\n";
print "\ta3\t04 10 00 06\t#moving eax into next memory location\n";
print "\tb8\t48 65 6c 6c\t#moving 'Hell' into eax\n";
print "\ta3\t00 10 00 06\t#moving eax into next memory location\n";
print "\tb9\t00 10 00 06\t#moving pointer to start of memory location into ecx\n";
print "\tba\t10 00 00 00\t#moving string size into edx\n";
print "\tbb\t01 00 00 00\t#moving 'stdout' number to ebx\n";
print "\tb8\t04 00 00 00\t#moving 'print out' syscall number to eax\n";
print "\tcd\t80\t\t#calling the linux kernel to execute our print to stdout\n";
print "\tb8\t01 00 00 00\t#moving 'sys_exit' call number to eax\n";
print "\tcd\t80\t\t#executing it via linux sys_call\n\n";
print "\tAssemble with: m2elf.pl --in inputfile --out outputfile --mem 16\n\n";
exit;
}
