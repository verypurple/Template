package Template::Parser;

use warnings;
use strict;

use PAL::Parser;

use Exporter qw(import); 
our @EXPORT = qw(parse_template parse_stack);

my $grammar = {
	STATEMENT => [
		['HTML'],
		['IDENTIFIER'],
		['IF_STATEMENT'],
		['FOR_STATEMENT'],
	],
	STATEMENTS => [
		['STATEMENT'],
		['STATEMENTS', 'STATEMENT']
	],
	IF_STATEMENT => [
		['IF', 'IDENTIFIER', 'STATEMENTS', 'END'],
		['IF', 'IDENTIFIER', 'STATEMENTS', 'ELSE', 'STATEMENTS', 'END'],
	],
	FOR_STATEMENT => [
		['FOR', 'IDENTIFIER', 'STATEMENTS', 'END'],
	],
};

my $p_funcs = {
	'STATEMENT : HTML' => \&p_stmt_html,
	'STATEMENT : IDENTIFIER' => \&p_stmt_identifier,
	'IF_STATEMENT : IF IDENTIFIER STATEMENTS END' => \&p_stmt_if_then,
	'IF_STATEMENT : IF IDENTIFIER STATEMENTS ELSE STATEMENTS END' => \&p_stmt_if_then_else,
	'FOR_STATEMENT : FOR IDENTIFIER STATEMENTS END' => \&p_stmt_for,
};

sub parse_template
{
	my ($tokens) = @_;

	return parse($grammar, 'STATEMENTS', $tokens, $p_funcs);
}

sub parse_stack
{
	my ($stack, $tokens) = @_;

	return build_ast($stack, $tokens, $p_funcs);
}

sub p_stmt_if_then
{
	return ['if-then', $_[1], $_[2]];
}

sub p_stmt_if_then_else
{
	return ['if-then-else', $_[1], $_[2], $_[4]];
}

sub p_stmt_html
{
	return ['html', $_[0]];
}

sub p_stmt_identifier
{
	return ['identifier', $_[0]];
}

sub p_stmt_for
{
	return ['for', $_[1], $_[2]];
}

1;
