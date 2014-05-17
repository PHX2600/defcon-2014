#!/usr/bin/env perl
use strict;
use IPC::Open3;

# this is a really bad sub-optimal ai, but it won 50 games
# expected solution may be to just upload a list of best moves

my $cmd = "nc 3dttt_87277cd86e7cc53d2671888c417f62aa.2014.shallweplayaga.me 1234";

my $pid = open3(\*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, $cmd)
    or die "open3() failed $!";

my $r;

CHLD_OUT->blocking(0);

my $c = 0;

my $b = "";

my @moves = ();
my @empty = ();

sub testComplete {
    my($i,$j,$k,$p) = @_;
    my $matchi = 1;
    my $matchj = 1;
    my $matchk = 1;

    for my $m (0..2) {
        if ($m != $i) {
            if ($moves[$m][$j][$k] eq $p) {
                $matchi++;
            }
        }
    }

    for my $n (0..2) {
        if ($n != $j) {
            if ($moves[$i][$n][$k] eq $p) {
                $matchj++;
            }
        }
    }

    for my $o (0..2) {
        if ($o != $k) {
            if ($moves[$i][$j][$o] eq $p) {
                $matchk++;
            }
        }
    }

    my @xyz = sort ($i,$j,$k);

    my @xy = sort ($i,$j);
    my @yz = sort ($j,$k);
    my @xz = sort ($i,$k);

    my @c1 = (0,0);
    my @c2 = (0,2);
    my @c3 = (2,2);

    my @cc1 = (0,0,0);
    my @cc2 = (0,0,2);
    my @cc2 = (0,2,2);
    my @cc3 = (2,2,2);

    my $matchxy = 1;
    my $matchyz = 1;
    my $matchxz = 1;
    my $matchxyz = 1;

    if (@xy~~@c1 or @xy~~@c2 or @xy~~@c3) {
        for my $c (0..2) {
            my $m = ($i==0?$c:$i-$c);
            my $n = ($j==0?$c:$j-$c);
            if ($moves[$m][$n][$k] eq $p) {
                $matchxy++;
            }
        }
    }

    if (@yz~~@c1 or @yz~~@c2 or @yz~~@c3) {
        for my $c (0..2) {
            my $n = ($j==0?$c:$j-$c);
            my $o = ($k==0?$c:$k-$c);
            if ($moves[$i][$n][$o] eq $p) {
                $matchyz++;
            }
        }
    }

    if (@xz~~@c1 or @xz~~@c2 or @xz~~@c3) {
        for my $c (0..2) {
            my $m = ($i==0?$c:$i-$c);
            my $o = ($k==0?$c:$k-$c);
            if ($moves[$m][$j][$o] eq $p) {
                $matchxz++;
            }
        }
    }

    if (@xyz~~@cc1 or @xyz~~@cc2 or @xyz~~@cc3 or @xyz~~@cc3) {
        for my $c (0..2) {
            my $m = ($i==0?$c:$i-$c);
            my $n = ($j==0?$c:$j-$c);
            my $o = ($k==0?$c:$k-$c);
            if ($moves[$m][$n][$o] eq $p) {
                $matchxyz++;
            }
        }
    }

    return $matchi*$matchj*$matchk*$matchxy*$matchyz*$matchxz*$matchxyz;
}


while (CHLD_OUT->opened()) {
    $r = <CHLD_OUT>;
    print $r;

    # first game has extra intro text, reset board text when z=0
    if ($r=~/z=0/) {
        $b = "";
    }
    $b .= $r;
    if ($r=~/Choose Wisely/) {
        my @board = split(/\n/,$b);

        for my $k (0..2) {
            for my $j (0..2) {
                for my $i (0..2) {
                    my $v = substr($board[2+(2*$j)+(9*$k)],3+(4*$i),1);
                    $moves[$i][$j][$k] = $v;
                    if ($v eq ' ') {
                        push(@empty,[$i,$j,$k]);
                    }
                }
            }
        }

        my $best = 0;
        if ($moves[1][1][1] eq ' ') {
            $best = [1,1,1];
        } else {

            # find the best move to take rows
            my $bestp = -1;
            foreach my $m (@empty) {
                my $p = testComplete(@$m,"X");
                if ($p > $bestp) {
                    $best = $m;
                    $bestp = $p;
                }
            }

            # look for a better way to block rows
            my $block = 0;
            my $blockp = -1;
            foreach my $m (@empty) {
                my $p = testComplete(@$m,"O");
                if ($p > $blockp) {
                    $block = $m;
                    $blockp = $p;
                }
            }

            if ($blockp >= $bestp) {
                $best = $block;
            }

            if ($best eq 0) {
                $best = [int(rand(3)),int(rand(3)),int(rand(3))];
            }
        }

        my $m = join(",",@$best);

        print "move: $m\n";
        print CHLD_IN "$m\n";
        @empty = ();
    } elsif ($r=~/Play better/) {
        CHLD_OUT->close();
    }
}
