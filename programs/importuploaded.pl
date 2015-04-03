#!/usr/bin/perl

# ------------------------------------------------------------------------------
# NIDB importuploaded.pl
# Copyright (C) 2004 - 2015
# Gregory A Book <gregory.book@hhchealth.org> <gbook@gbook.org>
# Olin Neuropsychiatry Research Center, Hartford Hospital
# ------------------------------------------------------------------------------
# GPLv3 License:
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# This program imports DICOM files that are uploaded from the website
# 
# [9/30/2013] - Greg Book
#		* Wrote initial program.
# -----------------------------------------------------------------------------

use strict;
use warnings;
use Mysql;
use Image::ExifTool;
use Net::SMTP::TLS;
use Data::Dumper;
use File::Path;
use File::Copy;
use File::Find;
use File::Basename;
use Cwd;
use File::Slurp;
use Switch;
use Sort::Naturally;
use String::CRC32;
use Digest::SHA qw(sha1 sha1_hex sha1_base64);

require 'nidbroutines.pl';
our %cfg;
LoadConfig();

# debugging
our $debug = 0;
our $dev = 0;

# database variables
our $db;

# script specific information
our $scriptname = "importuploaded";
our $lockfileprefix = "importuploaded";		# lock files will be numbered lock.1, lock.2 ...
our $lockfile = "";							# lockfile name created for this instance of the program
our $log;									# logfile handle created for this instance of the program
our $numinstances = 1;						# number of times this program can be run concurrently


# ------------- end variable declaration --------------------------------------
# -----------------------------------------------------------------------------


# check if this program can run or not
if (CheckNumLockFiles($lockfileprefix, $cfg{'lockdir'}) >= $numinstances) {
	print "Can't run, too many of me already running\n";
	exit(0);
}
else {
	my $logfilename;
	($lockfile, $logfilename) = CreateLockFile($lockfileprefix, $cfg{'lockdir'}, $numinstances);
	$logfilename = "$cfg{'logdir'}/$scriptname" . CreateLogDate() . ".log";
	open $log, '> ', $logfilename;
	my $x = DoImportUploaded();
	close $log;
	if (!$x) { unlink $logfilename; } # delete the logfile if nothing was actually done
	print "Done. Deleting $lockfile\n";
	unlink $lockfile;
}

exit(0);


# ----------------------------------------------------------
# --------- DoImportUploaded -------------------------------
# ----------------------------------------------------------
sub DoImportUploaded {
	my $time = CreateCurrentDate();
	WriteLog("$scriptname Running... Current Time is $time");

	my $ret = 0;
	
	# connect to the database
	DatabaseConnect();
	
	# check if this module should be running now or not
	if (!ModuleCheckIfActive($scriptname, $db)) {
		WriteLog("Not supposed to be running right now");
		SetModuleStopped();
		return 0;
	}
	
	# update the start time
	SetModuleRunning();

	# get list of pending uploads
	my $sqlstring = "select * from import_requests where import_status = 'pending'";
	WriteLog("[$sqlstring]");
	my $result = $db->query($sqlstring) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstring);
	if ($result->numrows > 0) {
		while (my %row = $result->fetchhash) {
			my $importrequest_id = $row{'importrequest_id'};
			my $siteid = $row{'import_siteid'};
			my $projectid = $row{'import_projectid'};
			my $anonymize = $row{'import_anonymize'};
			my $datatype = $row{'import_datatype'};
			my $modality = $row{'import_modality'};
			my $fileisseries = $row{'import_fileisseries'};
			my $importstatus = $row{'import_status'};
			
			if ($importstatus eq 'complete') {
				next;
			}
	
			my $sqlstringA = "update import_requests set import_status = 'receiving', import_startdate = now() where importrequest_id = $importrequest_id";
			my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
			
			my $uploaddir;
			
			if ($datatype eq '') { $datatype = "dicom"; }
			
			switch ($datatype) {
				case 'dicom' {
					# ----- get list of files in directory -----
					$uploaddir = $cfg{'uploadedpath'} . "/$importrequest_id";
					
					my @files;
					if (!opendir (DIR, $uploaddir)) {
						WriteLog("Could not open directory [$uploaddir] because [" . $! . "]");
						next;
					}
					while (my $file = readdir(DIR)) {
						#WriteLog($file);
						if ((trim($file) ne '.') && (trim($file) ne '..')) {
							push(@files,$file);
						}
					}
					closedir(DIR);
					my $numfiles = $#files + 1;
					WriteLog("Found $numfiles files in $uploaddir");
					
					# go through the files
					foreach my $file(@files) {
						my $filepath = "$uploaddir/$file";
						if (IsDICOMFile($filepath)) {
							# anonymize, replace project and site, rename, and dump to incoming
							#WriteLog("$filepath is a DICOM file");
							PrepareDICOM($importrequest_id,$filepath,$anonymize);
						}
						elsif ($filepath =~ m/\.par/) {
							PreparePARREC($importrequest_id,$filepath,$anonymize);
						}
						elsif ($filepath =~ m/\.rec/) {
							# .par/.rec are pairs, and only the .par contains meta-info, so leave the .rec alone
						}
						else {
							WriteLog("$filepath not a DICOM file");
							my ($ext) = $filepath =~ /(\..*)$/;

							my $tmppath = $cfg{'tmpdir'} . "/" . GenerateRandomString(10);
							my $systemstring = "";
							WriteLog("$filepath -> [$ext]");
							switch ($ext) {
								case /\.tar\.gz$/ { $systemstring = "tar -xvzf '$filepath' -C $tmppath"; }
								case /\.gz$/ { $systemstring = "gunzip -c '$filepath' -C $tmppath"; }
								case /\.z$/ { $systemstring = "gunzip -c '$filepath' -C $tmppath"; }
								case /\.Z$/ { $systemstring = "gunzip -c '$filepath' -C $tmppath"; }
								case /\.zip$/ { $systemstring = "unzip '$filepath' -d $tmppath"; }
								case /\.tar\.bz2$/ { $systemstring = "tar -xvjf '$filepath' -C $tmppath"; }
								case /\.tar$/ { $systemstring = "tar -xvf '$filepath' -C $tmppath"; }
							}
							if ($systemstring ne '') {
								mkpath($tmppath);
								WriteLog("$systemstring (" . `$systemstring 2>&1` . ")");
							
								# find all files in the /tmp dir and (anonymize,replace fields, rename, and dump to incoming)
								find(sub{FindDICOMs($importrequest_id,$anonymize);}, $tmppath);
							
								# delete the tmp directory
								if (($tmppath ne '') && ($tmppath ne '.') && ($tmppath ne '..')) {
									rmtree($tmppath);
								}
							}
						}
					}
					
					# move the beh directory if it exists
					if (-d "$uploaddir/beh") {
						mkpath("$cfg{'incomingdir'}/$importrequest_id");
						my $systemstring = "mv -v $uploaddir/beh $cfg{'incomingdir'}/$importrequest_id/";
						WriteLog("$systemstring (" . `$systemstring 2>&1` . ")");
					}
				}
				case 'eeg' {
					WriteLog("Encountered eeg import");
					# ----- get list of files in directory -----
					$uploaddir = $cfg{'uploadedpath'} . "/$importrequest_id";
					
					my @files;
					if (!opendir (DIR, $uploaddir)) {
						WriteLog("Could not open directory [$uploaddir] because [" . $! . "]");
						next;
					}
					while (my $file = readdir(DIR)) {
						if ((trim($file) ne '.') && (trim($file) ne '..')) {
							WriteLog("Found [$file]");
							push(@files,$file);
						}
					}
					closedir(DIR);
					my $numfiles = $#files + 1;
					WriteLog("Found $numfiles files in $uploaddir");
					
					# go through the files
					foreach my $file(@files) {
						my $filepath = "$uploaddir/$file";
						#PreparePARREC($importrequest_id,$filepath,$anonymize);
						WriteLog("Attempting mkpath(". $cfg{'incomingdir'} . "/$importrequest_id)");
						#WriteLog("[Long Listing 1] " . `ls -l $filepath`);
						mkpath("$cfg{'incomingdir'}/$importrequest_id",0777);
						my $systemstring = "touch $filepath; mv -v $filepath $cfg{'incomingdir'}/$importrequest_id/";
						WriteLog("$systemstring (" . `$systemstring 2>&1` . ")");
						#WriteLog("[Long Listing 2] " . `ls -l $cfg{'incomingdir'}/$importrequest_id/$file`);
					}
				}
				else {
					WriteLog("Datatype not recognized [$datatype]");
				}
			}
			
			my $sqlstringB = "update import_requests set import_status = 'received' where importrequest_id = $importrequest_id";
			my $resultB = $db->query($sqlstringB) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringB);
			
			# delete the uploaded directory
			WriteLog("Attempting to remove [$uploaddir]...");
			my $mode = (stat($uploaddir))[2];
			WriteLog(sprintf "permissions are %04o\n", $mode &07777);
			if (($uploaddir ne '.') && ($uploaddir ne '..') && ($uploaddir ne '') && ($uploaddir ne '/') && ($uploaddir ne '*')) {
				my $systemstring = "rm -rf $uploaddir";
				WriteLog("$systemstring (" . `$systemstring 2>&1` . ")");
			}
		}
		$ret = 1;
	}
	else {
		WriteLog("No rows in import_requests found");
	}
	
	#return 1;

	#my $i;
	#if ($i > 0) {
	#	WriteLog("Finished extracting data");
	#	$ret = 1;
	#}
	#else {
	#	WriteLog("Nothing to do");
	#}
	
	# update the stop time
	SetModuleStopped();
	
	return $ret;
}


# ----------------------------------------------------------
# --------- FindDICOMs -------------------------------------
# ----------------------------------------------------------
sub FindDICOMs {
	my ($id,$anonymize) = @_;

	my $file = $File::Find::name;
	my $newfile;
	
	if (!-d $file) {
		if (IsDICOMFile($file)) {
			PrepareDICOM($id,$file,$anonymize);
		}
	}
}


# ----------------------------------------------------------
# --------- PrepareDICOM -----------------------------------
# ----------------------------------------------------------
sub PrepareDICOM {
	my ($id,$file,$anonymize) = @_;
	my $newfile;
	
	# escape spaces in filenames. they dont work well with the backtick operator
	$file =~ s / /\\ /g;
	
	# if anonymization is requested, get the patient name and DOB
	my $exifTool = new Image::ExifTool;
	my $info = $exifTool->ImageInfo($file);
	my $PatientName = trim($info->{'PatientName'});
	my $PatientBirthDate = trim($info->{'PatientBirthDate'});
	
	my $hash1 = sha1_hex($PatientName);
	my $hash2 = sha1_hex($PatientBirthDate);
	
	my $anonstring = "";
	if ($anonymize) {
		$anonstring = "--replace 8,90='Anonymous' --replace 8,1050='Anonymous' --replace 8,1070='Anonymous' --replace 10,10='Anonymous-$hash1' --replace 10,30='Anonymous-$hash2'";
	}
	
	# replace fields using anonymize
	my $systemstring = "GDCM_RESOURCES_PATH=$cfg{'scriptdir'}/gdcm/Source/InformationObjectDefinition; export GDCM_RESOURCES_PATH; $cfg{'scriptdir'}/./gdcmanon -V --dumb -i $file $anonstring -o $file";
	#WriteLog("Anonymizing $file");
	#WriteLog("Anonymizing: (" . `$systemstring 2>&1` . ")");
	`$systemstring 2>&1`;
	
	# if the filename exists in the outgoing directory, prepend some junk to it, since the filename is unimportant
	# some directories have all their files named IM0001.dcm ..... so, inevitably, something will get overwrtten, which is bad
	my $filename = basename($file);
	#WriteLog("filename [$filename]");
	$newfile = GenerateRandomString(15) . $filename;
	#WriteLog("newfile [$newfile]");
	mkpath("$cfg{'incomingdir'}/$id",0777);
	$systemstring = "touch $file; mv $file $cfg{'incomingdir'}/$id/$newfile";
	#WriteLog("Moving the file (" . `$systemstring` . ")");
	`$systemstring 2>&1`;
}


# ----------------------------------------------------------
# --------- PreparePARREC ----------------------------------
# ----------------------------------------------------------
sub PreparePARREC {
	my ($id,$file,$anonymize) = @_;
	my $PatientName;
	
	# escape spaces in filenames. they dont work well with the backtick operator
	$file =~ s / /\\ /g;
	
	# if anonymization is requested, get the patient name and DOB
	# read the .par file into an array, get all the useful info out of it
	open (FH, "< $file") or die "Can't open $file for read: $!";
	my @lines = <FH>;
	close FH or die "Cannot close $file: $!";

	print "-----PAR file $file-----\n";
	
	foreach my $line (@lines) {
		$line = trim($line);
		#print "$line\n";
		if ($line =~ m/Patient name/) {
			my @parts = split(/:/, $line);
			$PatientName = trim($parts[1]);
			print "$PatientName\n";
			last;
		}
	}
	
	my $hash1 = sha1_hex($PatientName);
	
	if ($anonymize) {
		my $systemstring = "sed -i 's/$PatientName/$hash1/g' $file";
		#WriteLog("Anonymizing: ($systemstring)");
		#WriteLog("Anonymizing: (" . `$systemstring` . ")");
	}
	
	# if the filename exists in the outgoing directory, prepend some junk to it, since the filename is unimportant
	# some directories have all their files named IM0001.dcm ..... so, inevitably, something will get overwrtten, which is bad
	my $filename = basename($file);
	#WriteLog("filename [$filename]");
	my $newfilePAR = GenerateRandomString(15) . $filename;
	my $newfileREC = $newfilePAR;
	$newfileREC =~ s/\.par$/\.rec/;
	my $file2 = $file;
	$file2 =~ s/\.par$/\.rec/;
	
	WriteLog("newfilePAR [$newfilePAR] newfileREC [$newfileREC]");
	mkpath("$cfg{'incomingdir'}/$id",0777);
	my $systemstring = "touch $file; mv $file $cfg{'incomingdir'}/$id/$newfilePAR";
	WriteLog("Moving the file (" . `$systemstring 2>&1` . ")");
	$systemstring = "touch $file2; mv $file2 $cfg{'incomingdir'}/$id/$newfileREC";
	WriteLog("Moving the file (" . `$systemstring 2>&1` . ")");
}


# ----------------------------------------------------------
# --------- IsDICOMFile ------------------------------------
# ----------------------------------------------------------
sub IsDICOMFile {
	my ($f) = @_;
	
	# check if its really a dicom file...
	my $type = '';
	$type = Image::ExifTool::GetFileType($f);
	if (defined($type)) {
		#WriteLog("IsDICOMFile() filetype [$type]");
		if ($type ne "DICM") {
			return 0;
		}
	}
	else {
		#WriteLog("IsDICOMFile() filetype [Unknown]");
		return 0;
	}
	
	# get DICOM tags
	my $exifTool = new Image::ExifTool;
	my $tags = $exifTool->ImageInfo($f);
	
	if (defined($tags->{'Error'})) {
		return -1;
	}
	
	return 1;
}