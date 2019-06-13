#!/usr/bin/perl
#

use strict;
use warnings;

my %projcodes;
my %projnames;
my %activities;
my %acticodes;
my %actinames;
my %projbycode;
my %projbyname;
my %projinverse;
my %daydata;
my %codesary;
my %namesary;
my %magicinverse;

#my $username = $ENV{LOGNAME};
my $username = "richardbignell";
my $todaystr = "";
my $daydatafile = "";
my $projectlistfile = "";
my $activitylistfile = "";


mainloop();

# ----------------------------------------------------------------

# ----------------------------------------------------------------
# set up all the globals, given a todaystr for the data file
# ----------------------------------------------------------------
sub initialise
{
    $daydatafile = sprintf("%s-%s.csv",$username,$todaystr);

    printf("$daydatafile\n");

    $projectlistfile = "projects.csv";
    $activitylistfile = "activities.csv";

    read_projects();
    read_activities();
    read_day_so_far();
}

# ----------------------------------------------------------------
sub mainloop
{
    $todaystr = sprintf("%4.4d-%2.2d-%2.2d",
			(localtime)[5]+1900,
			(localtime)[4]+1,
			(localtime)[3]);

    initialise();

    while (1) {
	my $cmd;

        display_day_so_far();

        print("What> Add, Mod, Del, Whole-day, ch daTe, Rep, Quit (A,m,d,w,t,r,q): ");
        $cmd = <>;
        chomp($cmd);

        # default to add
        if (!length($cmd)) {
            $cmd = "a";
        }

	# quit
        if ($cmd =~ /q/i) {
            # we've already saved
            printf("\n");
            return;
        }

	# modify an existing entry
        if ($cmd =~ /m/i) {
            printf("\n");
            print("To modify, just add an entry at the same time as ");
            print("the one you want to change\n");
            printf("\n");
        }

	# add a single entry
        if ($cmd =~ /a/i) {
	    my ($t, $p, $k);

            printf("\n");
            $t = get_a_time();
            next if ($t =~ /ABORT/i);
            $p = get_a_project();
            next if ($p =~ /ABORT/i);
            $k = get_a_task($p);
            next if ($k =~ /ABORT/i);
            $daydata{$t} = $k;
            # save each change to minimise loss of data
            save_day_so_far();
        }

	# set a standard whole day to the same task
	# ASSUME THAT Out / Not Working IS 0000/0000
        if ($cmd =~ /w/i) {
	    my ($p, $k);

            printf("\n");
            $p = get_a_project();
            next if ($p =~ /ABORT/i);
            $k = get_a_task($p);
            next if ($k =~ /ABORT/i);
            $daydata{"09:00"} = $k;
            $daydata{"12:00"} = "0000/0000";
            $daydata{"13:00"} = $k;
            $daydata{"18:00"} = "0000/0000";
            # save each change to minimise loss of data
            save_day_so_far();
        }

	# change the date we're dealing with
	if ($cmd =~ /t/i) {
	    my $d;

            printf("\n");
	    $d = get_a_date();
            next if ($d =~ /ABORT/i);
	    # erase all the current information (if any)
	    delete @daydata{keys %daydata};
	    # we'll get back a clean date string, so we can just use it
	    $todaystr = $d;
	    # to reset all the globals and things
	    initialise();
	}

	# delete an entry
	if ($cmd =~ /d/i) {
	    my $t;

            printf("\n");
            $t = get_a_time();
            next if ($t =~ /ABORT/i);
            delete($daydata{$t});
            # save each change to minimise loss of data
            save_day_so_far();
	}

	# report the minutes per task for the day
	if ($cmd =~ /r/i) {
	    printf("\n");
	    report_day();
	}
    }
}

# ----------------------------------------------------------------
sub get_a_date
{
    my $defaultdate = "";
    my $newdate = "";
    my $input;

    $defaultdate = sprintf("%4.4d-%2.2d-%2.2d",
			   (localtime)[5]+1900,
			   (localtime)[4]+1,
			   (localtime)[3]);

    $newdate = "";
    while (!length($newdate)) {
	printf("New date to work with ($defaultdate or q): ");
	$input = <>;
	chomp($input);
	if (!length($input)) {
	    return($defaultdate);
	}
        if ($input =~ /q/i) {
            return("ABORT");
        }
	# this is an incomplete check, but not too bad
        if ($input =~ /^200[0-9]-[0-1][0-9]-[0-3][0-9]$/) {
            # date is ok
            return($input);
        }
        else {
            # date is not ok
            print("Date is not ok, try again.\n");
        }
    }

    return($newdate);
}

# ----------------------------------------------------------------
sub get_a_time
{
    my $eventtime = "";
    my $transtime = "";
    my $input;

    # times are strings formatted as "NN:NN" in 24-hour notation
    $transtime = sprintf("%2.2d:%2.2d",(localtime)[2],(localtime)[1]);

    $eventtime = "";
    while (!length($eventtime)) {
        print("Time of transition ($transtime or q): ");
        $input = <>;
        chomp($input);
        if (!length($input)) {
            return($transtime);
        }
        if ($input =~ /q/i) {
            return("ABORT");
        }
	# this is an incomplete check, but not too bad
        if ($input =~ /^[0-2][0-9]:[0-5][0-9]$/) {
            # time is ok
            return($input);
        }
        else {
            # time is not ok
            print("Time is not ok, try again.\n");
        }
    }

    return($eventtime);
}

# ----------------------------------------------------------------
sub get_a_project
{
    my $eventproject = "";
    my $num_projects;
    my @proj_indices = [];
    my $theindex;
    my $input;

    while (!length($eventproject)) {

        @proj_indices = display_projects();
        $num_projects = $#proj_indices;

        print("Enter a project index (or q to quit): ");
        $input = <>;
        chomp($input);
        if (!length($input)) {
            $input = "1";
        }
        if ($input =~ /q/i) {
            return "ABORT";
        }
        unless ($input =~ /^[0-9]+$/) {
            printf("Your response wasn't a number, try again.\n");
            next;
        }
        if ($input < 1 || $input > $num_projects) {
            printf("Out of range, try again.\n");
            next;
        }
        $theindex = $proj_indices[$input];
        return($projcodes{$theindex});
    }
}

# ----------------------------------------------------------------
sub read_projects
{
    my $index;
    my ($projcode, $projname);

    open(PROJECTS, "< $projectlistfile")
        or die "cannot open $projectlistfile for reading: $!\n";

    $index = 1;

    while(<PROJECTS>) {
        chomp;
        ($projcode, $projname) = split(/,/);

        $projcodes{$index} = $projcode;
        $projnames{$index} = $projname;
	$projinverse{$projcode} = $projname;

        $index += 1;
    }
    close(PROJECTS);
}

# ----------------------------------------------------------------
sub display_projects
{
    my $index;
    my @indices = [];

    $index = 1;
    foreach my $key (sort keys %projnames) {
        printf("%2d: %s\n", $index, $projnames{$key});
        $index += 1;
	push(@indices,$key);
    }
    return (@indices);
}

# ----------------------------------------------------------------
sub read_activities
{
    my $index = 1;
    my ($compoundcode, $compoundname);
    my ($projcode, $projname, $acticode, $actiname);

    open(ACTIVITIES, "< $activitylistfile")
        or die "cannot open $activitylistfile for reading: $!\n";
    while(<ACTIVITIES>) {
        chomp;
        ($projcode, $projname, $acticode, $actiname) = split(/,/);

        $compoundcode = $projcode . "/" . $acticode;
        $compoundname = $projname . " / " . $actiname;

        $codesary{$index} = $compoundcode;
        $namesary{$index} = $compoundname;
        $magicinverse{$compoundcode} = $compoundname;

        $index += 1;
    }
    close(ACTIVITIES);
}

# ----------------------------------------------------------------
sub get_a_task
{
    my $eventtask = "";
    my $projcode = $_[0];
    my @task_indices = [];
    my $theindex;
    my $input;
    my $num_tasks;

    while (!length($eventtask)) {

        @task_indices = display_project_tasks($projcode);
        $num_tasks = $#task_indices;

        print("Enter a task index (n for new, or q to quit): ");
        $input = <>;
        chomp($input);
        if (!length($input)) {
            $input = "1";
        }
        if ($input =~ /q/i) {
            return "ABORT";
        }
        if ($input =~ /n/i) {
            return "ABORT";
        }
        unless ($input =~ /^[0-9]+$/) {
            printf("Your response wasn't a number, try again.\n");
            next;
        }
        if ($input < 1 || $input > $num_tasks) {
            printf("Out of range, try again.\n");
            next;
        }
        $theindex = $task_indices[$input];
        return($codesary{$theindex});
    }
}

# ----------------------------------------------------------------
sub display_project_tasks
{
    my $index;
    my $projcode = $_[0];
    my @indices = [];

    $index = 1;
    foreach my $key (sort keys %namesary) {
        if ($codesary{$key} =~ /^$projcode\//) {
            printf("%2d: %s\n", $index, $namesary{$key});
            $index += 1;
            push(@indices,$key);
        }
    }
    return(@indices);
}

# ----------------------------------------------------------------
sub read_day_so_far
{
    my ($timstr, $projcode, $acticode);

#    unless (-f $daydatafile) {
#	system("touch $daydatafile");
#    }

    unless (-f $daydatafile) {
	open(TOTOUCH, "> $daydatafile") or die "cannot create empty $daydatafile: $!\n";
	close(TOTOUCH);
    }

    open(DAYDATA, "< $daydatafile")
        or die "cannot open to read $daydatafile: $!\n";
    while(<DAYDATA>) {
        chomp;
        ($timstr,$projcode,$acticode) = split(/,/);
        $daydata{$timstr} = $projcode . "/" . $acticode;
    }
    close(DAYDATA);
}

# ----------------------------------------------------------------
sub display_day_so_far
{
    my $combo;

    printf("\n");
    foreach my $t (sort keys %daydata) {
        $combo = $daydata{$t};
        printf(" %s  -  %s\n", $t, $magicinverse{$combo});
    }
    printf("\n");
}

# ----------------------------------------------------------------
sub save_day_so_far
{
    my $tmpname = "new-$daydatafile";
    my $bakname = "$daydatafile.bak";
    my $combo;
    my ($projcode, $acticode);

    open(DAYDATA, "> $tmpname")
        or die "cannot open to write $tmpname: $!\n";
    foreach my $t (sort keys %daydata) {
        $combo = $daydata{$t};
        ($projcode, $acticode) = split(/\//,$combo);
        printf(DAYDATA "%s,%s,%s\n",$t,$projcode,$acticode);
    }
    close(DAYDATA);
    rename($daydatafile,$bakname)
        or die "can't rename 1 $daydatafile -> $bakname: $!";
    rename($tmpname,$daydatafile)
        or die "can't rename 2 $tmpname -> $daydatafile: $!";
}

# ----------------------------------------------------------------
sub report_day
{
    my $minmark;
    my $prevtime;
    my $prevcombo;
    my %timecounts;
    my ($th, $tm, $tt);
    my ($hrs, $mins);
    my $delta;
    my $combo;

    $prevtime = 0;
    $prevcombo = "0000/0000";
    foreach my $t (sort keys %daydata) {
	($hrs, $mins) = split(/:/,$t);
	# convert to minutes since midnight
	$minmark = ($hrs * 60) + $mins;
	# how much time since the last change
	$delta = $minmark - $prevtime;
        $combo = $daydata{$t};
	$timecounts{$prevcombo} += $delta;
	$prevtime = $minmark;
	$prevcombo = $combo;
    }
    $th = 0;
    $tm = 0;
    $tt = 0;
    foreach my $c (sort keys %timecounts) {
	my ($h, $m);

	next if ($c eq "0000/0000");
	$h = $timecounts{$c} / 60;
	$m = $timecounts{$c} % 60;
	$tt += $timecounts{$c};
        printf(" %dh %dm  -  %s\n", $h, $m, $magicinverse{$c});
    }
    $th = $tt / 60;
    $tm = $tt % 60;
    printf(" %dh %dm  -  total for day\n", $th, $tm);
}
