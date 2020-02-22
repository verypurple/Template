package Template::Engine;

use warnings;
use strict;

use Template::Lexer;
use Template::Parser;
use Template::Common;
use File::Path;

use Exporter qw(import);
our @EXPORT = qw(render);

my $i_funcs = {
	'if-then' => \&i_stmt_if_then,
	'if-then-else' => \&i_stmt_if_then_else,
	'for' => \&i_stmt_for,
	'html' => \&i_stmt_html,
	'identifier' => \&i_stmt_identifier,
};

my $output;

sub render 
{
	my ($path, $data) = @_;

	$output = '';

	my $hash = `echo $path | sha1sum | cut -d' ' -f1`;
	chomp($hash);
	my $cache_dir = "/var/tmp/tplengine/parser-cache";
	my $cache_file = "$cache_dir/$hash";
	mkpath($cache_dir);

	my $tree;

	if (-e $cache_file) {
		my $data = read_file($cache_file);

		$tree = unserialize($data);
	}
	else {
		my $input = read_file($path);
		my $tokens = lex_template($input);
		my $stack = parse_template($tokens);
		
		$tree = parse_stack($stack, $tokens);

		my $data = serialize($tree);
		write_file($cache_file, $data);
	}

	if ($tree) {
		interpret($tree, $data);
		return $output;
	}
	else {
		return "Input is invalid.";
	}
}

sub interpret
{
	my ($tree, $context) = @_;

	for my $node (@$tree) {
		if (exists($i_funcs->{$node->[0]})) {
			$i_funcs->{$node->[0]}(@$node[1..$#$node], $context);
		}
		else {
			interpret($node, $context);
		}
	}
}

sub evaluate
{
	my ($exp, $context) = @_;

	# TODO: evaluate binop operators and other types of expressions
	return ref($context) eq 'HASH'
		&& exists($context->{$exp})
		&& $context->{$exp};
}

sub i_stmt_if_then
{
	my ($condition, $then, $context) = @_;

	i_stmt_if_then_else($condition, $then, [], $context);
}


sub i_stmt_if_then_else
{
	my ($condition, $then, $else, $context) = @_;

	if (evaluate($condition, $context)) {
		interpret($then, $context);
	}
	elsif ($else) {
		interpret($else, $context);
	}
}

sub i_stmt_for
{
	my ($identifier, $stmts, $context) = @_;

	for my $el (@{$context->{$identifier}}) {
		interpret($stmts, $el);
	}
}

sub i_stmt_html
{
	$output .= $_[0];
}

sub i_stmt_identifier
{
	my ($value, $context) = @_;

	if (ref($context) eq 'HASH') {
		if (exists($context->{$value})) {
			$output .= $context->{$value};
		}
	}
	else {
		$output .= $context;
	}
}

1;
