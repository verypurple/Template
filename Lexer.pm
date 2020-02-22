package Template::Lexer;

use warnings;
use strict;

use PAL::Lexer;

use Exporter qw(import);
our @EXPORT = qw(lex_template);

my $html_definitions = [
	[qr/^\{\{/, 'LBRACKET', \&t_lbracket],
	[qr/^.+?(?=\{\{|$)/s, 'HTML'],
];

my $tpl_definitions = [
	[qr/^\s+/, 'WHITESPACE', \&t_pass],
	[qr/^\}\}/, 'RBRACKET', \&t_rbracket],
	[qr/^if/, 'IF'],
	[qr/^else/, 'ELSE'],
	[qr/^for/, 'FOR'],
	[qr/^end/, 'END'],
	[qr/^\w+/, 'IDENTIFIER'],
];

sub lex_template
{
	my ($input) = @_;

	return lex($input, $html_definitions);
}

sub t_pass {
	return 0;
}

sub t_lbracket {
	set_definitions($tpl_definitions);

	return 0;
}

sub t_rbracket {
	set_definitions($html_definitions);

	return 0;
}
