package Term::Interact;

=head1 NAME

Term::Interact - Get Data Interactively From User

=head1 SYNOPSIS

  use Term::Interact;

  my $ti = Term::Interact->new( @args );

  # interactive
  $validated_value = $ti->get( @args );

  # non interactive
  $validated_value = $ti->sql_check( $value, @args );

  $validated_value = $ti->list_check( $value, @args );

  $validated_value = $ti->regex_check( $value, @args );

  $validated_value = $ti->compare_check( $value, @args );

=head1 DESCRIPTION

Term::Interact provides a way to interactively get values from the user.  It allows date, text and number processing through a I<simple> API.

The new() method constructs an object using default values and passed in parameters.  The get() method prompts the user for values and may use one or more C<check> methods to validate the values provided by the user.  These C<check> methods are also available for stand alone usage.  Check methods include:

=over 2

=item C<sql_check>

for checking input against the return value of SQL statements

=item C<regex_check>

for checking input against reqular expressions

=item C<list_check>

for checking input against a list of acceptable values

=item C<compare_check>

for checking that input satisfies one or more comparison expressions

=back

Finally, while this module steers clear of offering explicit checks like 'phone_number_check' or 'email_check', you may certainly add them by subclassing this module and simply providing the desired check as a subroutine.  Just follow the pattern of the built in checks in the source code for Term::Interact.

=head1 EXAMPLES

 # set up object
 my $ti = Term::Interact->new(
     date_format => '%d-%b-%Y',
     date_format_return => '%d-%b-%Y'
 );

 my $num1 = $ti->get(
     msg         => 'Enter a single digit number.',
     prompt      => 'Go ahead, make my day: ',
     re_prompt   => 'Try Again Here: ',
     regex_check => [
                      [
                        qr/^\d$/,
                        '%s is not a single digit number!'
                      ]
                    ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Enter a single digit number.
 #    Go ahead, make my day: w
 #    'w' is not a single digit number!
 #    Try Again Here: 23
 #    '23' is not a single digit number!
 #    Try Again Here: 2

 my $date = $ti->get (
     type          => 'date',
     name          => 'Date from 2001',
     confirm       => 1,
     compare_check => [
                        ['<= 12-31-2001', '%s is not %s.'],
                        ['>= 01/01/2001', '%s is not %s.'],
                      ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Date from 2001: Enter a value.
 #    > 2002-03-12
 #    You entered: '12-Mar-2002'. Is this correct? (Y|n)
 #    '12-Mar-2002' is not <= 31-Dec-2001.
 #    > foo
 #    'foo' is not a valid date
 #    > 2001-02-13
 #    You entered: '13-Feb-2001'. Is this correct? (Y|n)

 my $states_aref = $ti->get (
     msg       => 'Please enter a comma delimited list of states.',
     prompt    => 'State: ',
     re_prompt => 'Try Again: ',
     delimiter => ',',
     case      => 'uc',
     sql_check => [
                    $dbh,
                    [
                      'SELECT state FROM states ORDER BY state',
                      '%s is not a valid state code.  Valid codes are: %s'
                    ]
                  ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Please enter a comma delimited list of states.
 #    State: FOO
 #    'FOO' is not a valid state code.  Valid codes are: AA, AB, AE, AK,
 #    AL, AP, AQ, AR, AS, AZ, BC, CA, CO, CT, CZ, DC, DE, FL, FM, GA, GU,
 #    HI, IA, ID, IL, IN, KS, KY, LA, LB, MA, MB, MD, ME, MH, MI, MN, MO,
 #    MP, MS, MT, NB, NC, ND, NE, NF, NH, NJ, NM, NS, NT, NV, NY, OH, OK,
 #    ON, OR, PA, PE, PQ, PR, PW, RI, RM, SC, SD, SK, TN, TT, TX, UT, VA,
 #    VI, VT, WA, WI, WV, WY, YT
 #    Try Again: az, pa


 my $num2 = $ti->get (
     name          => 'Number Less Than 10 and More than 3',
     compare_check => [
                        [' < 10', '%s is not less than 10.'],
                        ['> 3', '%s is not %s.']
                      ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Number Less Than 10 and More than 3: Enter a value.
 #    > f
 #    'f' is not numeric.
 #    > 1
 #    '1' is not > 3.
 #    > -1
 #    '-1' is not > 3.
 #    > 14
 #    '14' is not less than 10.
 #    > 5

 my $grades = $ti->get (
     name       => 'Letter grade',
     delimiter  => ',',
     list_check => [ 'A', 'B', 'C', 'D', 'F' ]
 );
 #
 # Resulting Interaction looks like:
 #
 # Letter grade: Enter a value or list of values delimited with commas.
 #    > 1
 #    > s
 #    > X
 #    > a, b
 #    > A, B, C


 # If multiple checks are specified, the ordering
 #  is preserved if parms are passed as a list or aref.
 # In the example below, the sql_check will be applied
 #  before the regex_check.
 my $foo = $ti->get (
   [
     name        => $name,
     delimiter   => $delim,
     sql_check   => $aref_sql,
     regex_check => $aref_regex,
   ]
 );

 # If multiple checks are specified, the ordering
 #  is *not* preserved if parms are passed as an href
 my $foo = $ti->get (
   {
     name        => $name,
     delimiter   => $delim,
     sql_check   => $aref_sql,
     regex_check => $aref_regex,
   }
 );

 # multiple requests in one call to get method
 my ($foo, $bar) = $ti->get (
     [
       [
         name          => 'foo',
         compare_check => [ @check_arefs ],
       ],
       {
         name       => 'bar',
         delimiter  => ',',
         list_check => \@valid_values,
       },
     ]
 );

=head2 PARAMETERS

These parameters are available for use with new(), where they will be stored within the constructed object.  They are also available for use with get() and the C<check> methods, where they will override any values stored in the object, but only for the duration of that method call.  The parameter values stored in the object during construction will not be changed by any parameter values subsequently supplied to other methods.

=over 2

=item C<name>

I<str>: Used in auto-assembling a message for the user if no msg parameter was specified.

=item C<type>

I<str>: Currently, the only meaningful value for this parameter is 'date'.  If set to date, all input from the user and all check values supplied by the programmer will be parsed as dates by Date::Manip.

=item C<allow_null>

I<bool>: Defaults to 0.  Set to 1 to allow user to enter 'NULL', regardless of any other checking.  This is useful for database related prompting.

=item C<timeout>

I<num>: Defaults to 600 seconds.  Set to 0 to turn off the timeout functionality.  Timeout results in a fatal error which you may catch as you like.  (This option not available under MS Windows.)

=item C<maxtries>

I<num>: Defaults to 20.  Set to 0 turn off the maxtries functionality.  Exceeding the maxtries results in a fatal error which you must catch.

=item C<msg>

I<str>: Message that will print prior to user input prompt.  No msg will be printed if defined as 0.  If left undefined, a message will be auto-generated.

=item C<prompt>

I<str>: Defaults to '> '.  User will be prompted for input with this string.

=item C<reprompt>

I<str>: User will be re-prompted for input (as necessary) with this string.

=item C<case>

I<str>: The case of user input will be adjusted.  uc, lc, and ucfirst are available.

=item C<confirm>

I<bool>: The user will be prompted to confirm the input if set to 1.  Defaults to 0.

=item C<delimiter>

I<str>: Set this parameter to allow the user to enter multiple values via delimitation.  Note this is a string value, not a pattern.

=item C<delimiter_spacing>

I<str>: Defaults to 'auto', whereby one space will be added after each delimiter when prompting the user, and whitespace before and after any delimiters will be discarded when reading user input.  Set it to any value other than 'auto' to disable this behavior,

=item C<min_elem>

I<num>: Set this parameter to require the user to enter a minimum number of values.  Note this is a meaningful parameter only when used in conjunction with C<delimiter>.

=item C<max_elem>

I<num>: Set this parameter to restrict the user to a maximum number of values they can enter.  Note this is a meaningful parameter only when used in conjunction with C<delimiter>.

=item C<unique_elem>

I<bool>: Set this parameter to require all elements of the user-entered delimited value list to be unique.  Note this is a meaningful parameter only when used in conjunction with C<delimiter>.

=item C<default>

I<str> or I<aref>: If the user is permitted to input multiple values (i.e., you have specified a delimiter), you may specify multiple default values by passing them in an aref.  Or you may pass in one default value as a string.

=item C<date_format>

I<str>:  This string is used to format dates for diplay.  See Date::Manip's UnixDate function for details.  Defaults to '%c' if C<type> is set to 'date'.

=item C<date_format_return>

I<str>:  This string is used to format dates returned by Term::Interact methods.  See Date::Manip's UnixDate function for details.  If no date_format_return is specified, dates will be returned in epoch second format.

=item C<FH_OUT>

I<FH>: Defaults to STDOUT.  This filehandle will be used to print any messages to the user.

=item C<FH_IN>

I<FH>: Defaults to STDIN.  This filehandle will be used to read any input from the user.

=item C<term_width>

I<num>: Defaults to 72.  If the term_width of FH_OUT is less than the default or a value that you provide, the FH_OUT term_width will be used instead.

=item C<ReadMode>

I<num>:  Sets a ReadMode for user prompting.  Useful for turning terminal echo off for getting passwords.  See Term::ReadKey for details.  If set, ReadMode will be reset to 0 after each user input and in END processing.

=item C<sql_check>

I<aref>: The first element of this aref must be a valid database handle (See DBI for details).  Following that may be either SQL statements (one string each) or arefs consisting of one SQL statement and one error message each.  User-entered values must be found in the results of every SQL statement provided to be acceptable.  Examples:

=over 2

 [ $dbh, 'SELECT zing FROM zap', 'SELECT boo FROM dap' ]

 [
   $dbh,
   ['SELECT zing FROM zap', '%s is not a zing!'],
   [
     'SELECT boo FROM dap',
     '%s is not a boo!  Valid boos are %s'
   ]
 ]

=back 2

=item C<regex_check>

I<qr//> or I<aref>:  This parameter can be set to a single compiled regex, an aref with one compiled regex and one error message, or an aref with multiple compiled regexes or regex/error arefs.  User-entered values must match every regex provided to be acceptable.  Examples:

=over 2

 qr/^\d+$/

 [ qr/^\d+$/, 'That contained non-digits!' ]

 [
   [qr/^\d+/, "%s doesn't start with digits!"],
   qr/foo/
 ]

=back 2

=item C<list_check>

I<aref>: This aref contains legitimate values against which user input will be checked.

=item C<compare_check>

I<aref>: This aref contains one comparison test, a comparison test and error message, or arefs of comparison tests and error messages.  Operators will be split from the front of the comparison tests.  All perl operators except <=> and cmp (reasonably) are available.  Examples:

=over 2

 [ '>6' ]

 [ 'eq boo far', 'You did not say \'boo far\'!' ]

 [ '> 6', ' < 11' ] # whitespace around operator is ignored

 [
   ['>=6', '%s is not %s!'],
   ['<11', 'That was not less than eleven!'
 ]

 [ ['> 12/31/2015', '%s is not %s!'], '<11' ]

=back 2

=cut

#use diagnostics;
use strict;

# alarm not available under MS Windows
unless ($^O eq 'MSWin32') {
    use sigtrap 'handler' => sub{die "\n\nTimed out waiting for user input!\n"}, 'ALRM';
}

# trap interrupts
use sigtrap qw( die INT );

# make sure ReadMode is reset whe we're done
END {  ReadMode(0)  }

use Text::Autoformat;
use Term::ReadKey;
use Date::Manip;


use vars qw( $VERSION );

$VERSION = '0.40';

sub new {
    my $class = shift;
    my $self = bless {} => $class;
    my $args = $self->process_args( @_ );
    for (keys %{ $args }) {
        $self->{$_} = $args->{$_};
    }
    return $self;
}

# regex for recognizing a date already in epoch form -- used by more than one method()
my $qr_epoch = qr/^\-?\d+$/;

sub process_args {
    my $self = shift;

    ### @_ processing
    # we'll accept key value pairs as an array, aref, or an href
    if ($#_ == 0) {
        if (ref $_[0] eq 'HASH') {
            @_ = %{ $_[0] };
        } elsif (ref $_[0] eq 'ARRAY') {
            @_ = @{ $_[0] };
        } else {
            die "invalid arg";
        }
    }
    my %args = @_;

    # we set this flag before adding in the keys from %$self
    my $passed_args_include_ordered_checks_list = 1 if (exists $args{ordered_checks});

    ### $self processing
    # use anything from self that hasn't been specified by args
    for (keys %{$self}) {
        unless (exists $args{$_}) {
            $args{$_} = $self->{$_};
        }
    }

    ### %defaults setup
    my %defaults = (
        allow_null          => 0,
        timeout             => 600,
        maxtries            => 20,
        prompt              => '> ',
        confirm             => 0,
        echo_quote          => "'",
        delimiter_spacing   => 'auto',
        term_width          => 72,
    );
    for (keys %defaults) {
        unless (exists $args{$_}) {
            $args{$_} = $defaults{$_};
        }
    }

    ### Display related setup
    $args{FH_IN}  = \*STDIN  unless defined $args{FH_IN};
    $args{FH_OUT} = \*STDOUT unless defined $args{FH_OUT};
    my ($width) = GetTerminalSize( $args{FH_OUT} );
    $args{term_width}   = defined $args{term_width}
                        ? ($width < $args{term_width})
                            ? $width
                            : $args{term_width}
                        : $width;

    ### ordered_checks processing
    # if an ordered_checks list was passed in we'll honor it and not modify it
    unless ($passed_args_include_ordered_checks_list) {

        # if exists $args{ordered_checks}, it is a pointer to the list contained in $self.
        # let's make a copy of the contents of that data and modify the *copy*.  Otherwise,
        # if we modify the pointer in $args{ordered_checks}, we'll also end up with the
        # modified list in $self :-( .
        my @ordered_checks = (defined $args{ordered_checks}) ? @{$args{ordered_checks}} : ();

        for (@_) {
            if (defined and !ref and /_check$/) {
                my $check_name = $_;
                push @ordered_checks, $check_name unless (grep /$check_name/ => @ordered_checks);
            }
        }

        $args{ordered_checks} = \@ordered_checks;

    }

    ### Date related setup
    if (defined $args{type} and $args{type} eq 'date') {
        # accomodate time zone deficiency of Date::Manip under Win32
        set_TZ( (defined $args{time_zone}) ? $args{time_zone} : undef) if ($^O eq 'MSWin32');

        # set up date preprocessing
        if (defined $args{date_preprocess}) {
            die "date_preprocess value must be a coderef!" unless (ref $args{date_preprocess} eq 'CODE');
        } else {
            # Date::Manip interprets dates in format nn-nn-nnnn in a rather odd way (IMHO)...
            # So, let's trade those dashes for slashes to end up with the desired result
            # from Date::Manip
            my $qr_match = qr/^(\s*\d{2})\-(\d{2})\-(\d{4})/;
            $args{date_preprocess} = sub {
                my $date = shift;
                # switch those dashes to slashes!
                $date =~ s/$qr_match/$1\/$2\/$3/;
                return $date;
            };
        }

        # default the date formatting
        $args{date_format} = '%c' unless (defined $args{date_format});

        # convert any default value(s) to epoch seconds
        if (defined $args{default}) {
            if (ref $args{default}) {
                die "default value may only be an aref or scalar!" unless (ref $args{default} eq 'ARRAY');
                for (@{ $args{default} }) {
                    unless (/$qr_epoch/) {
                        my $epoch_seconds = UnixDate($args{date_preprocess}->($_),'%s') or die "Could not recognize default value $_ as a date!";
                        $_ = $epoch_seconds;
                    }
                }
            } else {
                unless ($args{default} =~ /$qr_epoch/) {
                    my $epoch_seconds = UnixDate($args{date_preprocess}->($args{default}),'%s') or die "Could not recognize default value $args{default} as a date!";
                    $args{default} = $epoch_seconds;
                }
            }
        }
    }

    return \%args
}

sub get {
    # # multiple parms
    # $ui->get(
    #           [
    #               $parm_1_href,
    #               $parm_2_aref,
    #           ]
    #         );
    #
    # # only 1 parm
    # $ui->get(
    #               $parm_key_1    =>  $parm_val_1,
    #               $parm_key_2    =>  $parm_val_2,
    #         );
    my $self = shift;
    my @parms;

    if ($#_ == 0) {
        if (ref $_[0] eq 'ARRAY'){
            for (@{$_[0]}) {
                die "Invalid element of aref arg to get method: $_!" if (ref and ref !~ m'HASH|ARRAY');
                push @parms, $_;
            }
        } elsif (ref $_[0] eq 'HASH'){
            $parms[0] = $_[0];
        } else {
            die "invalid arg: $_[0]";
        }
    } else {
        $parms[0] = [ @_ ];
    }

    my @return;
    for (@parms) {
        my $parm = $self->process_args( $_ );
        bless $parm => ref($self);

        my $OUT = $parm->{FH_OUT};
        my $IN  = $parm->{FH_IN};

        my $delimiter;
        my $delimiter_pattern;
        my $delimiter_pattern_split;
        my $delimiter_desc = '';
        if (defined $parm->{delimiter}) {
            $delimiter = $parm->{delimiter};
            $delimiter_pattern = quotemeta $delimiter;
            $delimiter_pattern_split = $delimiter_pattern;

            unless (defined $parm->{delimiter_spacing} and $parm->{delimiter_spacing} ne 'auto') {
                $delimiter_pattern_split = '\s*' . $delimiter_pattern_split . '\s*'
            }

            for ($delimiter_pattern, $delimiter_pattern_split) {
                $_ = qr/$_/;
            }

            if      ($delimiter eq ',') {
                $delimiter_desc = 'commas';
            } else {
                $delimiter_desc = $delimiter;
            }
        }

        # $w_ vars contain word strings to be combined later into appropriate prompts
        my $w_default;
        my $w_value_values = 'value';

        if (defined $parm->{msg}) {
            print $OUT  autoformat
                        (
                            $parm->interpolate
                            (
                                $parm->{msg},
                                defined $parm->{default}
                                  ? $parm->{default}
                                  : ()
                            ),
                            {all => 1, right => $parm->{term_width}}
                        )
                        if ($parm->{msg});
        } else {
            # This is the default message format
            #
            # [Name: ][The default value/values is/are LIST_HERE.  ]Enter a value[ or list of values delimited with DELIMITER_DESC_HERE][ (use the word NULL to indicate a null value/any null values)].

            my $msg;

            # set up words
            my $name = (defined $parm->{name}) ? "$parm->{name}: " : '';

            my $enter = 'Enter a value';

            my $default = '';
            my $w_is_are = 'is';
            if (defined $parm->{default} and $parm->{default} ne '') {
                $enter = 'enter a value';

                if (defined $delimiter) {
                    if (ref $parm->{default} eq 'ARRAY') {
                        my @defaults;
                        if(defined $parm->{type} and $parm->{type} eq 'date') {
                            push @defaults, UnixDate("epoch $_",$parm->{date_format}) for @{ $parm->{default} };
                        } else {
                            push @defaults, @{ $parm->{default} };
                        }
                        if ($#{ $parm->{default} }) {
                            $w_value_values = 'values';
                            $w_is_are = 'are';
                            $w_default = join "$delimiter " => @defaults;
                        } else {
                            $w_default = $parm->{default}->[0];
                        }
                    } else {
                        if (defined $parm->{type} and $parm->{type} eq 'date') {
                            $w_default = UnixDate('epoch ' . $parm->{default}, '%s' );
                        } else {
                            $w_default = $parm->{default};
                        }
                    }
                }

                $default =  "The default $w_value_values $w_is_are $w_default.  Press ENTER to accept the default, or ";
            }

            my $or_list_of_values = '';

            my $use_NULL_use_NULLs = ($parm->{allow_null})
                                     ? ' (use the word NULL to indicate a null value)'
                                     : '';

            if (defined $delimiter) {
                $or_list_of_values = " or list of values delimited with $delimiter_desc";
                $use_NULL_use_NULLs = ' (use the word NULL to indicate any null values)' if ($parm->{allow_null});
            }

            print $OUT autoformat(
                $name . $default . $enter . $or_list_of_values . $use_NULL_use_NULLs . '.',
                {all=>1, right=>$parm->{term_width}}
            );
        }


        my $ok = 0;
        my $i = 0;
        my $return;

        PROMPT:
        until ($ok) {
            if ($parm->{maxtries} and $i++ > $parm->{maxtries}) {
                die "You have exceeded the maximum number of allowable tries";
            }

            my $prompt;
            my $endspace = '';

            # autoformat kills any trailing space from the prompts, so this will recapture it
            my $get_endspace = sub {
                if ( $_[0] =~ /(\s+)$/ ) { $endspace = $1 }
            };

            if ($i > 1) {
                $prompt = (defined $parm->{re_prompt}) ? $parm->{re_prompt} : $parm->{prompt};
                $get_endspace->($prompt);
                $prompt =  autoformat( $prompt, {all=>1, left=>4, right=>$parm->{term_width}} );
            } else {
                $get_endspace->( $parm->{prompt} );
                $prompt = autoformat( $parm->{prompt}, {all=>1, left=>4, right=>$parm->{term_width}} );
            }
            chomp $prompt;
            $prompt .= $endspace;

            # allow for invisible user input
            ReadMode( $parm->{ReadMode}, $IN ) if (defined $parm->{ReadMode});

            alarm $parm->{timeout}  unless ($^O eq 'MSWin32');

            my $stdin;
            print $OUT $prompt;
            $stdin = <$IN>;
            chomp $stdin;

            alarm 0 unless ($^O eq 'MSWin32');

            # restore original console settings
            if (defined $parm->{ReadMode}) {
                ReadMode(0, $IN );
                print $OUT "\n" if ($parm->{ReadMode} == 2);
            }

            if ($stdin eq '') {
                next PROMPT unless (defined $parm->{default});
            } else {
                # split input into an aref if apropriate
                if (defined $delimiter and $stdin =~ /$delimiter_pattern/) {
                    unless (defined $parm->{delimiter_spacing} and $parm->{delimiter_spacing} ne 'auto') {
                        # get rid of any whitespace at front of string
                        $stdin =~ s/^\s*//;
                        # get rid of any delimiter and whitespace at beginning of string
                        $stdin =~ s/^$delimiter_pattern\s*//;
                    }
                    $stdin = [ split /$delimiter_pattern_split/ => $stdin ];
                    if (defined $parm->{min_elem}) {
                        if (scalar @$stdin < $parm->{min_elem}) {
                            my $elements = $parm->{min_elem} > 1 ? 'elements' : 'element';
                            print $OUT "You must specify at least $parm->{min_elem} $elements in your '$delimiter' delimited list\n";
                            next PROMPT;
                        }
                    }
                    if (defined $parm->{max_elem}) {
                        if (scalar @$stdin > $parm->{max_elem}) {
                            my $elements = $parm->{max_elem} > 1 ? 'elements' : 'element';
                            print $OUT "You may specify at most $parm->{max_elem} $elements in your '$delimiter' delimited list\n";
                            next PROMPT;
                        }
                    }
                    if (defined $parm->{unique_elem} and $parm->{unique_elem}) {
                        my %saw;
                        if ( scalar grep(!$saw{$_}++, @$stdin) != scalar @$stdin ) {
                            print $OUT "Each element of the '$delimiter' delimited list must be unique.\n";
                            next PROMPT;
                        }
                    }
                } else {
                    # put it into an aref anyway, for convenient processing
                    $stdin = [ $stdin ];
                }

                if (defined $parm->{case}) {
                    if ($parm->{case} eq 'uc') {
                        $_ = uc $_ for @$stdin;
                    } elsif ($parm->{case} eq 'lc') {
                        $_ = lc $_ for @$stdin;
                    } elsif ($parm->{case} eq 'ucfirst') {
                        $_ = ucfirst $_ for @$stdin;
                    } else {
                        die "Invalid case parameter: $parm->{case}"
                    }
                }

                # if date(s), convert to unix timevalue
                if (defined $parm->{type} and $parm->{type} eq 'date') {
                    for (@$stdin) {
                        unless (/^NULL$/i) {
                            my $time = UnixDate($parm->{date_preprocess}->($_),"%s");
                            if (defined $time) {
                                $_ = $time;
                            } else {
                                $_ = $parm->{echo_quote} . $_ . $parm->{echo_quote} if ($parm->{echo_quote});
                                print $OUT autoformat("$_ is not a valid date",{left=>4, right=>$parm->{term_width}});
                                next PROMPT;
                            }
                        }
                    }
                }
            }

            my $confirm = sub {
                my $prompt = shift;
                chomp $prompt;

                my $yn;
                print $OUT $prompt;
                $yn = <$IN>;
                chomp $yn;

                $yn = 'Y' if ($yn eq '');
                while ($yn !~ /[YyNn]/) {
                    print $OUT "    (Y|n) ";
                    $yn = <$IN>;
                    chomp $yn;
                }

                return ($yn =~ /y/i) ? 1 : 0;
            };

            if (defined $parm->{confirm} and $parm->{confirm}) {
                if (!ref $stdin and $stdin eq '') {
                    next PROMPT unless (
                        $confirm->(
                            autoformat(
                                "You accepted the default $w_value_values: $w_default.  Is this correct? (Y|n) ",
                                {all=>1, left=>4, right=>$parm->{term_width}}
                            )
                        )
                    );
                    $return = $parm->{default};
                } else {
                    my @confirm;
                    if (defined $parm->{type} and $parm->{type} eq 'date') {
                        push @confirm, UnixDate("epoch $_", $parm->{date_format}) for (@$stdin);
                    } else {
                        @confirm = @$stdin;
                    }

                    if ($parm->{echo_quote}) {
                        $_ = $parm->{echo_quote} . $_ . $parm->{echo_quote} for @confirm;
                    }

                    next PROMPT unless (
                        $confirm->(
                            autoformat(
                                "You entered: " .
                                (
                                (defined $delimiter) ? join("$delimiter " => @confirm) : $confirm[0]
                                ) .
                                ".  Is this correct? (Y|n) ",
                                {all=>1, left=>4, right=>$parm->{term_width}}
                            )
                        )
                    );
                }
            } else {
                $return = $parm->{default} if (!ref $stdin and $stdin eq '');
            }

            if (ref $stdin or $stdin ne '') {
                for (@{$parm->{ordered_checks}}) {
                    my @parms = ();
                    push @parms, (date_format_return => '%s') if (defined $parm->{type} and $parm->{type} eq 'date');
                    if (/custom_check/) {
                        $return = $parm->{$_}->($stdin, @parms);
                        next PROMPT unless defined $return;
                    } else {
                        push @parms, (cache_sql_results => 1) if (/sql_check/);
                        $return = $parm->$_($stdin, @parms);
                        next PROMPT unless defined $return;
                    }
                }
            }

            # Catch anything that fell through
            $return = $stdin unless defined $return;

            $return = [ $return ] unless (ref $return eq 'ARRAY');

            $ok = 1;
        }

        if (defined $parm->{type} and $parm->{type} eq 'date') {
            if (defined $parm->{date_format_return}) {
                $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$return;
            }
        }

        # calling program determines whether an aref or scalar is returned via the delimiter parm
        push @return, ((defined $delimiter) ? $return : $return->[0]);
    }

    return $#parms ? @return : $return [0];

}

sub regex_check {
    my $self = shift;
    my $aref = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    die "regex_check was invoked, but no regex_check-specific information was found!" unless (defined $parm->{regex_check});

    unless (ref $aref eq 'ARRAY') {
        die "First arg to regex_check must be aref or scalar" if (ref $aref);
        $aref = [ $aref ];
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        die "regex_check is not a valid option in conjunction with a parm type of 'date'!";
    }

    my $qr_NULL = (defined $parm->{allow_null} and $parm->{allow_null})
                ? qr/^NULL$/i
                : '';

    my $check = sub {
        my ($try,$regex) = (shift,shift);
        my $err_msg = (@_) ? shift : '';
        return 1 if ($qr_NULL and $try =~ /$qr_NULL/);
        return 1 if ($try =~ /$regex/);
        print $OUT ( autoformat( $parm->interpolate($err_msg,$try,$regex), {all=>1, left=>4, right=>$parm->{term_width}} ) ) if ($err_msg);
        return undef;
    };

    for (@$aref) {
        if (ref $parm->{regex_check} eq 'ARRAY') {
            if (
                scalar @{ $parm->{regex_check} } == 2
                    and
                ref $parm->{regex_check}->[0] eq 'Regexp'
                    and
                !ref $parm->{regex_check}->[1]
               ){
                return undef unless $check->( $_, @{ $parm->{regex_check} } );
            } else {
                for my $regex (@ {$parm->{regex_check} }) {
                    if (ref $regex eq 'ARRAY') {
                        die "Invalid number of elements in regex_check aref" if ($#{$regex} != 1);
                        die "Not a regex: " . $regex->[0] unless (ref $regex->[0] eq 'Regexp');
                        die "Not a vaild regex_check error message: " . $regex->[1] unless (!ref $regex->[1]);
                        return undef unless $check->( $_, @$regex );
                    } else {
                        die "Not a regex: $regex" unless (ref $regex eq 'Regexp');
                        return undef unless /$regex/;
                    }
                }
            }
        } else {
            die "Not a regex: " . $parm->{regex_check} unless (ref $parm->{regex_check} eq 'Regexp');
            return undef unless $check->( $parm, $_, $parm->{regex_check} );
        }
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        if (defined $parm->{date_format_return}) {
            $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$aref;
        }
    }

    return $aref;
}


sub sql_check {
    my $self = shift;
    my $aref = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    die "sql_check was invoked, but no sql_check-specific information was found!" unless (defined $parm->{sql_check});

    unless (ref $aref eq 'ARRAY') {
        die "First arg to sql_check must be aref or scalar" if (ref $aref);
        $aref = [ $aref ];
    }

    my $dbh;
    die "value for sql_check must be an aref!" unless (ref $parm->{sql_check} eq 'ARRAY');
    for (@{ $parm->{sql_check} }) {
        # first element must be $dbh
        unless (defined $dbh) {
            $dbh = $_;
            die "No database handle was provided!" unless (ref $dbh and $dbh->can( 'trace' ));
        }

        if (ref eq 'ARRAY') {
            # unless we already looked up the values
            if (!ref $_->[0] and $_->[0] =~ /^\s*SELECT/io) {
                die "Invalid number of elements in sql_check aref" if ($#{$_} != 1);
                die "Invalid err_msg" unless (defined $_->[1] and !ref $_->[1]);
                $_->[0] = $dbh->selectcol_arrayref( $_->[0] ) or die "This SQL statement did not return any rows: $_->[0]";
                if (defined $parm->{type} and $parm->{type} eq 'date') {
                    for (@{$_->[0]}) {
                        my $epoch_seconds = 'epoch ' . UnixDate($parm->{date_preprocess}->($_),'%s') or die "Could not recognize $_ as a date!";
                        $_ = $epoch_seconds;
                    }
                }
            }
        } else {
            if (!ref $_ and $_ =~ /^\s*SELECT/io) {
                $_ = $dbh->selectcol_arrayref( $_ ) or die "This SQL statement did not return any rows: $_";
                if (defined $parm->{type} and $parm->{type} eq 'date') {
                    for ( @$_ ) {
                        my $epoch_seconds = 'epoch ' . UnixDate($parm->{date_preprocess}->($_),'%s') or die "Could not recognize $_ as a date!";
                        $_ = $epoch_seconds;
                    }
                }
            }
        }
    }
    # if requested, store our revised sql_check value in
    # $self to avoid another database lookup next time.
    $self->{sql_check} = $parm->{sql_check} if (defined $parm->{cache_sql_results} and $parm->{cache_sql_results});

                                                   # let's leave out the $dbh, it's not wanted by list_check
    my $return = $parm->list_check( $aref, list_check => [ @{ $parm->{sql_check} }[1..$#{ $parm->{sql_check} }] ] );
    return $return;
}

sub list_check {
    my $self = shift;
    my $aref = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    die "list_check was invoked, but no list_check-specific information was found!" unless (defined $parm->{list_check});

    unless (ref $aref eq 'ARRAY') {
        die "First arg to list_check must be aref or scalar" if (ref $aref);
        $aref = [ $aref ];
    }

    die "No list_check aref was given!" unless (defined $parm->{list_check} and ref $parm->{list_check} eq 'ARRAY');

    my $parse_date;
    $parse_date = sub {
        die "parse_date only accepts one parm" if $#ARGV;
        my $list = (ref $_[0] eq 'ARRAY') ? $_[0] : [$_[0]];
        for (@$list) {
            if (/^\s*epoch\s+(\-?\d+)\s*$/io) {
                s/.*/$1/;
            } else {
                my $epoch_seconds = UnixDate($parm->{date_preprocess}->($_),'%s')
                    or die "Could not recognize $_ as a date!";
                $_ = $epoch_seconds;
            }
        }
        return (ref $_[0] eq 'ARRAY') ? $list : $list->[0];
    } if (defined $parm->{type} and $parm->{type} eq 'date');

    my @lists_n_errs;

    # valid input:
    #
    # LEVEL 1:     [ 1,2,3 ]
    # LEVEL 2: [ [ [ 1,2,3 ], 'err' ], [ 1,2,3 ], ... ]

    # if LEVEL 1
    if ( !ref $parm->{list_check}->[0] ) {
        $parm->{list_check} = $parse_date->( $parm->{list_check} ) if (defined $parse_date);
        push @lists_n_errs, [ $parm->{list_check} ];
    # if LEVEL 2
    } else {
        for ( @{$parm->{list_check}} ) {
            die "invalid element" unless (ref eq 'ARRAY');
            if (ref $_->[0] eq 'ARRAY') {
                $_->[0] = $parse_date->( $_->[0] ) if (defined $parse_date);
                push @lists_n_errs, $_;
            } else {
                $_ = $parse_date->( $_ ) if (defined $parse_date);
                push @lists_n_errs, [ $_ ];
            }
        }
    }

    my $qr_NULL = (defined $parm->{allow_null} and $parm->{allow_null})
                ? qr/^NULL$/i
                : '';

    for my $val (@$aref) {
        unless ($qr_NULL and $val =~ /$qr_NULL/) {
            for (@lists_n_errs) {
                my ($list,$err_msg) = @$_;
                unless (grep /^$val$/ => @$list) {
                    print $OUT (
                        autoformat(
                            $parm->interpolate(
                                $err_msg,
                                $val,
                                join(
                                    (
                                        (defined $parm->{delimiter})
                                        ? "$parm->{delimiter} "
                                        : ', '
                                    ),
                                    (
                                        (defined $parm->{type} and $parm->{type} eq 'date')
                                        ? map { UnixDate("epoch $_",$parm->{date_format}) } @$list
                                        : @$list
                                    )
                                )
                            ),
                            {all=>1, left=>4, right=>$parm->{term_width}}
                        )
                    ) if (defined $err_msg);
                    return undef;
                }
            }
        }
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        if (defined $parm->{date_format_return}) {
            $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$aref;
        }
    }
    return $aref;
}

sub compare_check {
    my $self = shift;
    my $aref = shift;
    my $parm = $self->process_args( @_ );
    bless $parm => ref($self);

    my $OUT = $parm->{FH_OUT};

    die "compare_check was invoked, but no compare_check-specific information was found!" unless (defined $parm->{compare_check});

    unless (ref $aref eq 'ARRAY') {
        die "First arg to compare_check must be aref or scalar" if (ref $aref);
        $aref = [ $aref ];
    }

    my $qr_cmp = qr/^(\s*(lt|gt|le|ge|eq|ne|cmp|<=>|<=|>=|==|!=|<|>)\s*)/;
    my $qr_numeric = qr/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;  # from perlfaq

    my @checks;
    for (@{$parm->{compare_check}}) {
        my $err_msg = '';
        my $cmp_val;
        if (ref $_ eq 'ARRAY') {
            die "Invalid number of elements in compare_check aref" if ($#{$_} != 1);
            ($cmp_val,$err_msg) =  @$_;
        } else {
            $cmp_val = $_;
        }
        my $orig_cmp_val = $cmp_val;
        # match and cut comparison operator from front of string
        $cmp_val =~ s/$qr_cmp//;
        # capture matched comparison operator
        my $cmp = $2;

        if ($cmp eq '<=>' or $cmp eq 'cmp') {
            die "$cmp is not an acceptable comparison operator for the compare_check method!";
        }

        if (defined $parm->{type} and $parm->{type} eq 'date') {
            my $epoch_seconds = UnixDate($parm->{date_preprocess}->($cmp_val),'%s') or die "Could not recognize comparison value $cmp_val as a date!";
            $cmp_val = $epoch_seconds;
            # as we're keeping track of this comparison check for possible use by an error message, let's conform
            # it to the desired formatting.
            $orig_cmp_val = "$cmp " . UnixDate("epoch $epoch_seconds", $parm->{date_format});
        }
        push @checks, [$cmp, $cmp_val, $orig_cmp_val, $err_msg];
    }

    for my $val (@$aref) {
        for (@checks) {
            my ($cmp, $cmp_val, $orig_cmp_val, $err_msg) = @$_;
            if ($cmp =~ /(<|>|<=|>=|==|!=)/) {
                if ($val =~ /$qr_numeric/) {
                    if    ($cmp eq '<'  ) { unless ($val <   $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                    elsif ($cmp eq '>'  ) { unless ($val >   $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                    elsif ($cmp eq '<=' ) { unless ($val <=  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                    elsif ($cmp eq '>=' ) { unless ($val >=  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                    elsif ($cmp eq '==' ) { unless ($val ==  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                    elsif ($cmp eq '!=' ) { unless ($val !=  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                    else                  { die "Unknown comparison operator: $cmp" }
                } else {
                    print $OUT ( autoformat("'$val' is not numeric.", {all=>1, left=>4, right=>$parm->{term_width}}) );
                    return undef;
                }
            } else {
                if    ($cmp eq 'lt' ) { unless ($val lt  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                elsif ($cmp eq 'gt' ) { unless ($val gt  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                elsif ($cmp eq 'le' ) { unless ($val le  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                elsif ($cmp eq 'ge' ) { unless ($val ge  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                elsif ($cmp eq 'eq' ) { unless ($val eq  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                elsif ($cmp eq 'ne' ) { unless ($val ne  $cmp_val) { print $OUT ( autoformat($parm->interpolate($err_msg,$val,$orig_cmp_val),{all=>1, left=>4, right=>$parm->{term_width}}) ) if ($err_msg); return undef; } }
                else                  { die "Unknown comparison operator: $cmp" }
            }
        }
    }

    if (defined $parm->{type} and $parm->{type} eq 'date') {
        if (defined $parm->{date_format_return}) {
            $_ = UnixDate("epoch $_",$parm->{date_format_return}) for @$aref;
        }
    }

    return $aref;
}

sub star_obscure {
    my $self = shift;
    return @_ unless (defined $self->{ReadMode} and $self->{ReadMode} == 2);

    my $aref = ref $_[0]
               ? $_[0]
               : [ $_[0] ];

    for (@$aref) {
        if (length() < 6) {
            $_ = '******';
        } else {
            s/./*/g;
        }
    }

    return ref $_[0] ? $aref : $aref->[0];
}


sub format_for_display {
    my $self = shift;
    my $aref = ref $_[0] eq 'ARRAY'
               ? $_[0]
               : [ $_[0] ];
    my $date_format = (defined $self->{type} and $self->{type} eq 'date')
                      ? $self->{date_format}
                      : '';

    for (@$aref) {
        if ($date_format and /$qr_epoch/) {
            $_ = UnixDate("epoch $_",$date_format);
        }
    }
    return join
    (
        defined $self->{delimiter}
          ? "$self->{delimiter} "
          : ', '
        =>
        @$aref
    );
}

sub interpolate {
    my $self = shift;
    my $picture = shift;

    # interpolate the contents of @_ into $picture
    my $qr_sprintf_s = qr/\%s/;
    if ( $picture =~ /$qr_sprintf_s/ ) {
        if ($self->{echo_quote}) {
            $picture =~ s/$qr_sprintf_s/$self->{echo_quote}%s$self->{echo_quote}/;
        }
        return sprintf($picture, map {$self->format_for_display($_)} @_);
    } else {
        return $picture;
    }
}

sub set_TZ ($) {
    my $time_zone = shift;

    # Date::Manip cannot determine the time zone under windows, so in the interest
    # of portability we'll help out.
    unless (defined $main::TZ) {
        if (defined $time_zone) {
            $main::TZ = $time_zone;
        } else {
            # the following code (to determine a timezone for Date::Manip)
            # is attributed to a usenet post by Larry Rosler
            my ($l_min, $l_hour, $l_year, $l_yday) = (localtime $^T)[1, 2, 5, 7];
            my ($g_min, $g_hour, $g_year, $g_yday) = (   gmtime $^T)[1, 2, 5, 7];
            my $tzval = ($l_min - $g_min)/60 + $l_hour - $g_hour + 24 * ($l_year <=> $g_year || $l_yday <=> $g_yday);
            $tzval = sprintf( "%2.2d00", $tzval);
            $tzval = '+' . $tzval unless ($tzval =~ /^\-/);

            # Versions of Date::Manip prior to 5.41 don't understand hour offset TZ values
            if (DateManipVersion() <= 5.4) {
                # This is a cheesy cross ref between hour offsets (gotten above)
                # and alpha TZ codes.  This is *really* suboptimal because of course
                # more than one alpha TZ code corresponds with each hour offset.
                # You can avoid this by passing in a TZ instead.
                my %tz = qw( -1200 IDLW -1100 NT -1000 HST -0900 AKST -0800 PST -0700 MST -0600 CST -0500 EST -0400 AST -0300 ADT -0200 AT -0200 SAST -0100 WAT +0000 UTC +0100 CET +0200 EET +0300 MSK +0400 ZP4 +0500 ZP5 +0600 ZP6 +0800 CCT +0900 JST +1000 EAST +1100 EADT +1200 NZST +1300 NZDT );
                $tzval = $tz{$tzval} or die "*Really* unexpected error";
            }
            $main::TZ = $tzval;
        }
    }
}

1;
__END__

=head1 AUTHOR

Term::Interact by Phil R Lawrence.

=head1 COPYRIGHT

The Term::Interact module is Copyright (c) 2002 Phil R Lawrence.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 NOTE

This module was developed while I was in the employ of Lehigh University.  They kindly allowed me to have ownership of the work with the understanding that I would release it to open source.  :-)

=head1 SEE ALSO

Text::Autoformat, Term::ReadKey, Date::Manip

=cut



FUTURE development:
    allow for not lists?
        - sql_check_not
        - regex_check_not
        - list_check_not
        - allow for quoting of input echos
           e.g.,
             Tue Dec 12 00:00:00 2045 is not < Mon Dec 31 00:00:00 2001.
               vs.
             'Tue Dec 12 00:00:00 2045' is not < 'Mon Dec 31 00:00:00 2001'.
