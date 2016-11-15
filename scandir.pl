#! /usr/bin/perl

# === Description ===
# 'scandir' scans a directory tree and prints out file and directory attributes in a tabulator separated format.
#   It ignores subdirectories on other file systems.
#

use strict;

### set software constants ###

my $software_id = "{19ea07a3-a9e6-4d75-b08c-92e37c33c210}";
my $software_name = "scandir.pl";
my $software_version = "0.0.0011";
my $software_created_on      = "2016-08-04";
my $software_created_by      = "debock.de";
my $software_last_changed_on = "2016-11-14";
my $output_format_version = "0.1";

### read system parameter ##

my $now;
my ($username, $hostname);

### global variables ###

my ($dir, @attr, $mtime, $ctime, $size, $dev_nr_fs);
my ($global_dev_nr_fs);
my ($link_target);

### main start ###

my $directory = ".";
my $depth = 0;

my $dir_cnt = 0;
my $file_cnt = 0;
my $link_cnt = 0;


if ($ARGV[0] ne '') {
  $directory = $ARGV[0];
}

if (-d "$directory")
{

  print_header_comment();

  print_m_kv ('scan_directory', $directory);
  
  my @attr = stat("$directory");
  $global_dev_nr_fs = $attr[0];
  print_comment ("Device number of start directory:", $global_dev_nr_fs);
  print_info ("dev_nr", $global_dev_nr_fs);
  
  scan_dir($directory);
  
  print_footer_comment();
}
else {
  print "Directory \"$directory\" not found\n";
  exit(2);
}

### main end ###


### subroutines ###

sub print_header_comment
{
  print_comment("$software_name $software_version (last change: $software_last_changed_on)");
  print_comment('  software id', $software_id);
  print_comment('output format version', $output_format_version);
  
  
  print_m_kv('software_id', $software_id);
  print_m_kv('software_name', $software_name);
  print_m_kv('software_version', $software_version);
  print_m_kv('output_format_version', $output_format_version);
  
  print_m_kv('call', $0);
  print_m_kv('call_parameter', join(' ', @ARGV));
  $hostname = `hostname`; chomp($hostname);
  print_m_kv('hostname', $hostname);
  $username = `whoami`; chomp($username);
  print_m_kv('user', $username);

  $now = time();
  
  print_m_kv('scan_id', datetime_to_digits($now) . "." . int(rand(10000000000)));
  print_m_kv('start_unitime', $now);
  print_m_kv('start_isotime', datetime_to_iso($now));
}

sub print_footer_comment
{
  $now = time();
  print_m_kv('end_unitime', $now);
  print_m_kv('end_isotime', datetime_to_iso($now));
}

sub print_comment
{
  print ('# ', join(' ', @_), "\n");
}

sub print_error
{
  print ("m\terr\t", shift(@_), "\t", join("\t", @_), "\n");
}

sub print_warning
{
  print ("m\twarn\t", shift(@_), "\t", join("\t", @_), "\n");
}

sub print_info
{
  print ("m\tinfo\t", shift(@_), "\t", join("\t", @_), "\n");
}


sub print_m_kv
{
  print ("M\t\kv\t$_[0]\t\t$_[1]\n");
}

sub datetime_to_iso
{
  my @tvals = gmtime($_[0]);
  my $year  = $tvals[5]+1900;
  my $month = to_two_digits($tvals[4]+1);
  my $day   = to_two_digits($tvals[3]);
  my $hour  = to_two_digits($tvals[2]);
  my $min   = to_two_digits($tvals[1]);
  my $sec   = to_two_digits($tvals[0]);
  return ("$year-$month-$day $hour:$min:$sec");
}

sub datetime_to_digits
{
  my @tvals = gmtime($_[0]);
  my $year  = $tvals[5]+1900;
  my $month = to_two_digits($tvals[4]+1);
  my $day   = to_two_digits($tvals[3]);
  my $hour  = to_two_digits($tvals[2]);
  my $min   = to_two_digits($tvals[1]);
  my $sec   = to_two_digits($tvals[0]);
  return ("$year$month$day$hour$min$sec");
}

sub to_two_digits
{
  my $ret = $_[0];
  if ($_[0] < 10) { $ret = "0$ret" }
  return ($ret);
}

sub scan_dir
{
  $depth++;
  my $upper_directory = $_[0]; 
  my $dir_name = $_[1];
  my $upper_dir_id = $_[2];
  my $directory = $upper_directory;
  if ($dir_name ne '') {  
    if ($directory ne '/') { 
      $directory = "$directory/$dir_name";
    }
    else {
      $directory = "$directory$dir_name";
    }
  }
  
  my (@entries, $entry);
  my $incline;
  $dir_cnt++;
  my $dir_id = $dir_cnt;
  
  # query directory attributes
  @attr = stat("$directory");
  $mtime = $attr[9];
  $ctime = $attr[10];
  $dev_nr_fs = $attr[0];
  
  # return if different device for file system
  if ($dev_nr_fs != $global_dev_nr_fs) {
    print_comment ("directory '$directory' on different device: dev_nr_fs:$dev_nr_fs - global_dev_nr_fs:$global_dev_nr_fs");
    print_info ('other_dev', $directory, $dev_nr_fs, $global_dev_nr_fs);
    return;
  }
  
  print "D\t$dir_id\t$upper_dir_id\t$dir_name\t$directory\t$ctime\t$mtime\n";
  if (!opendir ($dir, $directory)) {
    print_error('could_not_open_dir', $dir_id, $upper_dir_id, $dir_name, $directory);
    return 0;
  }
  @entries = readdir $dir;
  
  # print file attributes
  foreach $entry (@entries)
  {
    if (($entry ne '..') && ($entry ne '.'))
    {
	    if (-f "$directory/$entry")
      {
	      @attr = stat("$directory/$entry");
	      ($mtime, $ctime, $size) = ($attr[9], $attr[10], $attr[7]);
		    $file_cnt++;
        print "F\t$file_cnt\t$dir_id\t$entry\t$size\t$ctime\t$mtime\n";
	    }
      elsif (-l "$directory/$entry" && !(-d "$directory/$entry")) {
        @attr = lstat("$directory/$entry");
	      ($mtime, $ctime, $size) = ($attr[9], $attr[10], $attr[7]);
        $link_target = readlink ("$directory/$entry");
		    $link_cnt++;
        print "L\tF\t$link_cnt\t$dir_id\t$entry\t$size\t$ctime\t$mtime\t$link_target\n";
      }
    }
  }
  
  # scan all subdirectories
  foreach $entry (@entries)
  {
    if (($entry ne '..') && ($entry ne '.'))
    {
	    if (-d "$directory/$entry") {
        if (-l "$directory/$entry") { 
          @attr = lstat("$directory/$entry");
          ($mtime, $ctime, ) = ($attr[9], $attr[10]);
          $link_target = readlink ("$directory/$entry");
          print "L\tD\t$directory\t$entry\t$directory/$entry\t$ctime\t$mtime\t$link_target\n";
        }
	      else { 
          scan_dir("$directory", "$entry", $dir_id);
        }
	    }
    }
  }
  
  
  closedir $dir;
  $depth--;
}
