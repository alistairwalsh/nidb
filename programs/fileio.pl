#!/usr/bin/perl

# ------------------------------------------------------------------------------
# NIDB fileio.pl
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
# This program performs file moving/copying/deleting data on disk when requested
# from the web front end
# 
# [9/10/2013] - Greg Book
#		* Wrote initial program.
# -----------------------------------------------------------------------------

use strict;
use warnings;
use Mysql;
use Net::SMTP::TLS;
use Data::Dumper;
use File::Path;
use File::Copy;
use File::Find;
use Image::ExifTool;
use Switch;
use Sort::Naturally;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
require 'nidbroutines.pl';

our %cfg;
LoadConfig();

# script specific information
our $scriptname = "fileio";
our $lockfileprefix = "fileio";		# lock files will be numbered lock.1, lock.2 ...
our $numinstances = 1;			# number of times this program can be run concurrently
our $debug = 0;

our $lockfile;
our $log;
our $db;


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
	#my $logfilename = "$lockfile";
	$logfilename = "$cfg{'logdir'}/$scriptname" . CreateLogDate() . ".log";
	open $log, '> ', $logfilename;
	my $x = DoIO();
	close $log;
	if (!$x) { unlink $logfilename; } # delete the logfile if nothing was actually done
	print "Done. Deleting $lockfile\n";
	unlink $lockfile;
}

exit(0);


# ----------------------------------------------------------
# --------- DoIO -------------------------------------------
# ----------------------------------------------------------
sub DoIO {
	# no idea why, but perl is buffering output to the screen, and these 3 statements turn off buffering
	my $old_fh = select(STDOUT);
	$| = 1;
	select($old_fh);
	
	my $old_fh2 = select($log);
	$| = 1;
	select($old_fh2);
	
	my $time = CreateCurrentDate();
	WriteLog("$scriptname Running... Current Time is $time");

	my %dicomfiles;
	my $ret = 0;
	
	# connect to the database
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("Connected to database");

	# check if this module should be running now or not
	if (!ModuleCheckIfActive($scriptname, $db)) {
		WriteLog("Not supposed to be running right now");
		return 0;
	}
	
	# update the start time
	ModuleDBCheckIn($scriptname, $db);

	# get list of things to delete
	my $sqlstring = "select * from fileio_requests where request_status != 'complete' and request_status != 'deleting' and request_status != 'error'";
	my $result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	if ($result->numrows > 0) {
		while (my %row = $result->fetchhash) {
			my $fileiorequest_id = $row{'fileiorequest_id'};
			my $fileio_operation = $row{'fileio_operation'};
			my $data_type = $row{'data_type'};
			my $data_id = $row{'data_id'};
			my $data_destination = $row{'data_destination'};
			my $modality = $row{'modality'};
			my $dicomtags = $row{'anonymize_fields'};
			
			my $found = 0;
			switch ($fileio_operation) {
				case 'createlinks' {
					switch ($data_type) {
						case 'analysis' { $found = CreateLinks($data_id, $cfg{'mountdir'}.$data_destination); $found = 1; }
					}
				}
				case 'copy' {
					switch ($data_type) {
						case 'analysis' { $found = CopyAnalysis($data_id, $cfg{'mountdir'}.$data_destination); $found = 1; }
					}
				}
				case 'delete' {
					switch ($data_type) {
						case 'pipeline' { $found = DeletePipeline($data_id); }
						case 'analysis' { $found = DeleteAnalysis($data_id); }
						case 'groupanalysis' { $found = DeleteGroupAnalysis($data_id); }
						case 'subject' { $found = DeleteSubject($data_id); }
						case 'study' { $found = DeleteStudy($data_id); }
						case 'series' { $found = DeleteSeries($data_id,$modality); }
					}
				}
				case 'detach' {
				}
				case 'move' {
				}
				case 'anonymize' {
					$found = AnonymizeSeries($fileiorequest_id,$data_id,$modality,$dicomtags);
				}
				case 'rearchive' {
					switch ($data_type) {
						case 'study' { $found = RearchiveStudy($data_id); }
						case 'subject' { $found = RearchiveSubject($data_id); }
					}
				}
			}
			
			if ($found) {
				# set the status of the delete_request to complete
				my $sqlstringA = "update fileio_requests set request_status = 'complete' where fileiorequest_id = $fileiorequest_id";
				WriteLog($sqlstringA);
				my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
			}
			elsif (!$found) {
				# wrong data_type, so set it to 'error'
				my $sqlstringA = "update fileio_requests set request_status = 'error' where fileiorequest_id = $fileiorequest_id";
				WriteLog($sqlstringA);
				my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
			}
			else {
				# some error occurred, so set it to 'error'
				my $sqlstringA = "update fileio_requests set request_status = 'error', request_message = '$found' where fileiorequest_id = $fileiorequest_id";
				WriteLog($sqlstringA);
				my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
			}
		}
		WriteLog("Finished performing file IO");
		$ret = 1;
	}
	else {
		WriteLog("Nothing to do");
	}
	
	# update the stop time
	ModuleDBCheckOut($scriptname, $db);

	return $ret;
}


# ----------------------------------------------------------
# --------- CopyAnalysis -----------------------------------
# ----------------------------------------------------------
sub CopyAnalysis() {
	my ($analysisid,$destination) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In CopyAnalysis($analysisid,$destination)");
	
	# check if destination is somewhat valid, if so create it
	if (($destination ne "") && ($destination ne ".") && ($destination ne "..") && ($destination ne "/")) {
	
		my $sqlstring = "select d.uid, b.study_num, e.pipeline_name from analysis a left join studies b on a.study_id = b.study_id left join enrollment c on b.enrollment_id = c.enrollment_id left join subjects d on c.subject_id = d.subject_id left join pipelines e on a.pipeline_id = e.pipeline_id where a.analysis_id = $analysisid";
		WriteLog($sqlstring);
		my $result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
		my %rowA = $result->fetchhash;
		my $uid = $rowA{'uid'};
		my $studynum = $rowA{'study_num'};
		my $pipelinename = $rowA{'pipeline_name'};

		# check to see if anything isn't valid or is blank
		if (!defined($cfg{'analysisdir'})) { WriteLog("Something was wrong, cfg->analysisdir was not initialized"); return "cfg->analysisdir was not initialized"; }
		if (!defined($uid)) { WriteLog("Something was wrong, uid was not initialized"); return "uid was not initialized"; }
		if (!defined($studynum)) { WriteLog("Something was wrong, studynum was not initialized"); return "studynum was not initialized"; }
		if (!defined($pipelinename)) { WriteLog("Something was wrong, pipelinename was not initialized"); return "pipelinename was not initialized"; }
		if (trim($cfg{'analysisdir'}) eq '') { WriteLog("Something was wrong, cfg->analysisdir was blank"); return "analysisdir"; }
		if (trim($uid) eq '') { WriteLog("Something was wrong, uid was blank"); return "UID was blank"; }
		if (trim($studynum) eq '') { WriteLog("Something was wrong, studynum was blank"); return "studynum was blank"; }
		if (trim($pipelinename) eq '') { WriteLog("Something was wrong, pipelinename was blank"); return "Pipelinename was blank"; }

		my $datapath = $cfg{'mountdir'} . $cfg{'analysisdir'} . "/$uid/$studynum/$pipelinename";

		$destination = "$destination/$uid$studynum";
		if (-e $destination) {
			WriteLog("Path [$destination] exists");
		}
		else {
			my @dirparts = split('/', $destination);
			my $newpath = '';
			foreach my $part(@dirparts) {
				if (trim($part) ne '') {
					$newpath .= "/$part";
					if (!-e $newpath) {
						WriteLog("Attempting to make [$newpath]");
						mkpath($newpath, { verbose => 1, mode => 0777 });
					}
					else {
						WriteLog("[$newpath] already exists");
					}
				}
			}
		}		
		if (($datapath ne "") && ($datapath ne ".") && ($datapath ne "..") && ($datapath ne "/")) {
			my $systemstring = "cp -ruv $datapath $destination";
			WriteLog("[$systemstring] :" . `$systemstring 2>&1`);
		}
		return 1;
	}
	else {
		return 'Invalid destination';
	}
}


# ----------------------------------------------------------
# --------- CreateLinks ------------------------------------
# ----------------------------------------------------------
sub CreateLinks() {
	my ($analysisid,$destination) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In CopyAnalysis($analysisid,$destination)");
	
	# check if destination is somewhat valid, if so create it
	if (($destination ne "") && ($destination ne ".") && ($destination ne "..") && ($destination ne "/")) {
	
		my $sqlstring = "select d.uid, b.study_num, e.pipeline_name from analysis a left join studies b on a.study_id = b.study_id left join enrollment c on b.enrollment_id = c.enrollment_id left join subjects d on c.subject_id = d.subject_id left join pipelines e on a.pipeline_id = e.pipeline_id where a.analysis_id = $analysisid";
		WriteLog($sqlstring);
		my $result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
		my %rowA = $result->fetchhash;
		my $uid = $rowA{'uid'};
		my $studynum = $rowA{'study_num'};
		my $pipelinename = $rowA{'pipeline_name'};

		# check to see if anything isn't valid or is blank
		if (!defined($cfg{'analysisdir'})) { WriteLog("Something was wrong, cfg->analysisdir was not initialized"); return "cfg->analysisdir was not initialized"; }
		if (!defined($uid)) { WriteLog("Something was wrong, uid was not initialized"); return "uid was not initialized"; }
		if (!defined($studynum)) { WriteLog("Something was wrong, studynum was not initialized"); return "studynum was not initialized"; }
		if (!defined($pipelinename)) { WriteLog("Something was wrong, pipelinename was not initialized"); return "pipelinename was not initialized"; }
		if (trim($cfg{'analysisdir'}) eq '') { WriteLog("Something was wrong, cfg->analysisdir was blank"); return "analysisdir"; }
		if (trim($uid) eq '') { WriteLog("Something was wrong, uid was blank"); return "UID was blank"; }
		if (trim($studynum) eq '') { WriteLog("Something was wrong, studynum was blank"); return "studynum was blank"; }
		if (trim($pipelinename) eq '') { WriteLog("Something was wrong, pipelinename was blank"); return "Pipelinename was blank"; }

		my $datapath = $cfg{'mountdir'} . $cfg{'analysisdir'} . "/$uid/$studynum/$pipelinename";

		#$destination = "$destination/$uid$studynum";
		if (-e $destination) {
			WriteLog("Path [$destination] exists");
		}
		else {
			my @dirparts = split('/', $destination);
			my $newpath = '';
			foreach my $part(@dirparts) {
				if (trim($part) ne '') {
					$newpath .= "/$part";
					if (!-e $newpath) {
						WriteLog("Attempting to make [$newpath]");
						mkpath($newpath, { verbose => 1, mode => 0777 });
					}
					else {
						WriteLog("[$newpath] already exists");
					}
				}
			}
		}
		# if there is a /mount prefix, remove it
		if ($datapath =~ /\/mount/) {
			$datapath =~ s/\/mount//;
		}
		if (($datapath ne "") && ($datapath ne ".") && ($datapath ne "..") && ($datapath ne "/")) {
			my $systemstring = "cd $destination; ln -s $datapath $uid$studynum; chmod 777 $uid$studynum";
			WriteLog("[$systemstring] :" . `$systemstring 2>&1`);
		}
		return 1;
	}
	else {
		return 'Invalid destination';
	}
}


# ----------------------------------------------------------
# --------- DeletePipeline ---------------------------------
# ----------------------------------------------------------
sub DeletePipeline() {
	my ($id) = @_;

	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	
	WriteLog("In DeletePipeline()");
	
	# get list of analyses associated with this pipeline
	my $sqlstring = "select * from analysis where pipeline_id = $id";
	my $result = $db->query($sqlstring) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstring);
	if ($result->numrows > 0) {
		while (my %row = $result->fetchhash) {
			my $analysisid = $row{'analysis_id'};
			DeleteAnalysis($analysisid);
		}
	}
	else {
		WriteLog("No analyses to delete");
		#return "No analyses to delete";
		# there were no series to process
	}
	
	# delete the actual pipeline entry
	$sqlstring = "delete from pipelines where pipeline_id = $id";
	$result = $db->query($sqlstring) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstring);
	return 1;
}


# ----------------------------------------------------------
# --------- DeleteAnalysis ---------------------------------
# ----------------------------------------------------------
sub DeleteAnalysis() {
	my ($analysisid) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In DeleteAnalysis()");
	
	#my $analysisid = $id;
	
	my $sqlstring = "select a.analysis_qsubid, d.uid, b.study_num, e.pipeline_name, e.pipeline_level, e.pipeline_directory from analysis a left join studies b on a.study_id = b.study_id left join enrollment c on b.enrollment_id = c.enrollment_id left join subjects d on c.subject_id = d.subject_id left join pipelines e on a.pipeline_id = e.pipeline_id where a.analysis_id = $analysisid";
	WriteLog($sqlstring);
	my $result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	my %rowA = $result->fetchhash;
	my $uid = $rowA{'uid'};
	my $studynum = $rowA{'study_num'};
	my $pipelinename = $rowA{'pipeline_name'};
	my $pipelinelevel = $rowA{'pipeline_level'};
	my $pipelinedirectory = $rowA{'pipeline_directory'};
	my $sgeid = $rowA{'analysis_qsubid'};

	if ($pipelinelevel == 0) {
		my $d = $pipelinedirectory;
		
		if (($d ne "") && ($d ne ".") && ($d ne "..") && ($d ne "/")) {
			WriteLog("Datapath: $d");
			rmtree($d,1,1);
		
			# clear the entry from the database
			my $sqlstringA = "delete from analysis_data where analysis_id = $analysisid";
			WriteLog($sqlstringA);
			my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
					
			my $sqlstringB = "delete from analysis_results where analysis_id = $analysisid";
			WriteLog($sqlstringB);
			my $resultB = $db->query($sqlstringB) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringB);

			my $sqlstringC = "delete from analysis where analysis_id = $analysisid";
			WriteLog($sqlstringC);
			my $resultC = $db->query($sqlstringC) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringC);
			
			return 1;
		}
	}
	else {
		# check to see if anything isn't valid or is blank
		if (!defined($cfg{'analysisdir'})) { WriteLog("Something was wrong, cfg->analysisdir was not initialized"); return; }
		if (!defined($uid)) { WriteLog("Something was wrong, uid was not initialized"); return; }
		if (!defined($studynum)) { WriteLog("Something was wrong, studynum was not initialized"); return; }
		if (!defined($pipelinename)) { WriteLog("Something was wrong, pipelinename was not initialized"); return; }
		if (trim($cfg{'analysisdir'}) eq '') { WriteLog("Something was wrong, cfg->analysisdir was blank"); return; }
		if (trim($uid) eq '') { WriteLog("Something was wrong, uid was blank"); return; }
		if (trim($studynum) eq '') { WriteLog("Something was wrong, studynum was blank"); return; }
		if (trim($pipelinename) eq '') { WriteLog("Something was wrong, pipelinename was blank"); return; }

		# attempt to kill the SGE job, if its running
		my $systemstring = "/sge/sge-root/bin/lx24-amd64/./qdelete $sgeid";
		WriteLog("Attempting to kill the SGE job [$sgeid]" . `$systemstring 2>&1`);
		
		my $datapath = $cfg{'analysisdir'} . "/$uid/$studynum/$pipelinename";
		
		if (($datapath ne "") && ($datapath ne ".") && ($datapath ne "..") && ($datapath ne "/")) {
			WriteLog("Datapath: $datapath");
			rmtree($datapath,1,1);
		
			# check if the directory still exists
			if (-e $datapath) {
				my $sqlstringA = "update analysis set analysis_statusmessage = 'Analysis directory not deleted. Manually delete the directory and then delete from this webpage again' where analysis_id = $analysisid";
				WriteLog($sqlstringA);
				my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
			}
			else {
				# clear the entry from the database
				my $sqlstringA = "delete from analysis_data where analysis_id = $analysisid";
				WriteLog($sqlstringA);
				my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
						
				my $sqlstringB = "delete from analysis_results where analysis_id = $analysisid";
				WriteLog($sqlstringB);
				my $resultB = $db->query($sqlstringB) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringB);

				my $sqlstringC = "delete from analysis where analysis_id = $analysisid";
				WriteLog($sqlstringC);
				my $resultC = $db->query($sqlstringC) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringC);
			}			
			return 1;
		}
		else {
			WriteLog("Something was wrong, datapath was [$datapath]");
			return "Something was wrong, datapath was [$datapath]";
		}
	}
	return 0;
}


# ----------------------------------------------------------
# --------- DeleteGroupAnalysis ----------------------------
# ----------------------------------------------------------
sub DeleteGroupAnalysis() {
	my ($analysisid) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In DeleteGroupAnalysis()");
	
	#my $analysisid = $id;
	
	my $sqlstring = "select d.uid, b.study_num, e.pipeline_name from analysis a left join studies b on a.study_id = b.study_id left join enrollment c on b.enrollment_id = c.enrollment_id left join subjects d on c.subject_id = d.subject_id left join pipelines e on a.pipeline_id = e.pipeline_id where a.analysis_id = $analysisid";
	WriteLog($sqlstring);
	my $result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	my %rowA = $result->fetchhash;
	#my $uid = $rowA{'uid'};
	#my $studynum = $rowA{'study_num'};
	my $pipelinename = $rowA{'pipeline_name'};

	# check to see if anything isn't valid or is blank
	if (!defined($cfg{'groupanalysisdir'})) { WriteLog("Something was wrong, cfg->groupanalysisdir was not initialized"); return; }
	#if (!defined($uid)) { WriteLog("Something was wrong, uid was not initialized"); return; }
	#if (!defined($studynum)) { WriteLog("Something was wrong, studynum was not initialized"); return; }
	if (!defined($pipelinename)) { WriteLog("Something was wrong, pipelinename was not initialized"); return; }
	if (trim($cfg{'groupanalysisdir'}) eq '') { WriteLog("Something was wrong, cfg->groupanalysisdir was blank"); return; }
	#if (trim($uid) eq '') { WriteLog("Something was wrong, uid was blank"); return; }
	#if (trim($studynum) eq '') { WriteLog("Something was wrong, pipelinename was blank"); return; }
	if (trim($pipelinename) eq '') { WriteLog("Something was wrong, pipelinename was blank"); return; }

	my $datapath = $cfg{'groupanalysisdir'} . "/$pipelinename";
	
	if (($datapath ne "") && ($datapath ne ".") && ($datapath ne "..") && ($datapath ne "/")) {
		WriteLog("Datapath: $datapath");
		rmtree($datapath,1,1);
	
		# clear the entry from the database
		my $sqlstringA = "delete from analysis_data where analysis_id = $analysisid";
		WriteLog($sqlstringA);
		my $resultA = $db->query($sqlstringA) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringA);
				
		my $sqlstringB = "delete from analysis_results where analysis_id = $analysisid";
		WriteLog($sqlstringB);
		my $resultB = $db->query($sqlstringB) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringB);

		my $sqlstringC = "delete from analysis where analysis_id = $analysisid";
		WriteLog($sqlstringC);
		my $resultC = $db->query($sqlstringC) || SQLError("[File: " . __FILE__ . " Line: " . __LINE__ . "]" . $db->errmsg(),$sqlstringC);
		
		return 1;
	}
	else {
		WriteLog("Something was wrong, datapath was [$datapath]");
		return "Something was wrong, datapath was [$datapath]";
	}
}


# ----------------------------------------------------------
# --------- DeleteSubject ----------------------------------
# ----------------------------------------------------------
sub DeleteSubject() {
	my ($id) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In DeleteSubject()");
	
	my $sqlstring = "select uid from subjects where subject_id = $id";
	WriteLog($sqlstring);
	my $result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	my %row = $result->fetchhash;
	my $uid = $row{'uid'};
	
	# move all archive data to the deleted directory
	my $newpath = $cfg{'deletedpath'} . "/" . GenerateRandomString(10) . "-$uid";
	mkpath($newpath, { verbose => 1, mode => 0777 });
	my $systemstring = "mv " . $cfg{'archivedir'} . "/$uid $newpath/";
	WriteLog("Running [$systemstring]");
	WriteLog(`$systemstring 2>&1`);
	
	# remove all database entries about this subject:
	# TABLES: subjects, subject_altuid, subject_relation, studies, *_series, enrollment, family_members, mostrecent
	$sqlstring = "delete from mostrecent where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	$sqlstring = "delete from family_members where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	$sqlstring = "delete from subject_relation where subjectid1 = $id or subjectid2 = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);

	$sqlstring = "delete from subject_altuid where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all series
	$sqlstring = "delete from mr_series where study_id in (select study_id from studies where enrollment_id in (select enrollment_id from enrollment where subject_id = $id))";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all studies
	$sqlstring = "delete from studies where enrollment_id in (select enrollment_id from enrollment where subject_id = $id)";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all enrollments
	$sqlstring = "delete from enrollment where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete the subject
	$sqlstring = "delete from subjects where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
}


# ----------------------------------------------------------
# --------- DeleteStudy ------------------------------------
# ----------------------------------------------------------
sub DeleteStudy() {
	my ($id) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In DeleteStudy()");
}


# ----------------------------------------------------------
# --------- DeleteSeries -----------------------------------
# ----------------------------------------------------------
sub DeleteSeries() {
	my ($id) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In DeleteSeries()");
}


# ----------------------------------------------------------
# --------- RearchiveStudy ---------------------------------
# ----------------------------------------------------------
sub RearchiveStudy() {
	my ($studyid) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In RearchiveStudy()");
	
	# get path info
	my $sqlstring = "select c.uid, a.study_num, b.project_id from studies a left join enrollment b on a.enrollment_id = b.enrollment_id left join subjects c on b.subject_id = c.subject_id where a.study_id = $studyid";
	my $result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	my %row = $result->fetchhash;
	my $uid = $row{'uid'};
	my $studynum = $row{'study_num'};
	my $projectRowID = $row{'project_id'};
	my $studypath = $cfg{'archivedir'} . "/$uid/$studynum";
	
	# get instanceID
	$sqlstring = "select instance_id from projects where project_id = '$projectRowID'";
	$result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	%row = $result->fetchhash;
	my $instanceRowID = $row{'instance_id'};
	
	# create an import request, based on the current instance, project, and site & get next import ID
	$sqlstring = "insert into import_requests (import_datatype, import_datetime, import_status, import_equipment, import_siteid, import_projectid, import_instanceid, import_uuid, import_anonymize, import_permanent) values ('dicom',now(),'uploading','','','$projectRowID', '$instanceRowID', '','','')";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	my $uploadID = $result->insertid;
	my $outpath = $cfg{'uploadedpath'} . "/$uploadID";
	mkpath($outpath, { verbose => 1, mode => 0777 });
	
	# move all DICOM, par/rec, nifti files to the /dicomincoming directory
	# find all files in the /tmp dir and (anonymize,replace fields, rename, and dump to incoming)
	WriteLog("Calling find($studypath)");
	find(sub{MoveDICOMs($outpath);}, $studypath);
	
	# move the study directory to the deleted directory
	my $newpath = $cfg{'deletedpath'} . "/$uid-$studynum-" . GenerateRandomString(10);
	mkpath($newpath, { verbose => 1, mode => 0777 });
	my $systemstring = "mv $studypath $newpath";
	WriteLog("Running $systemstring: [" . `$systemstring 2>&1` . "]");

	$sqlstring = "update import_requests set import_status = 'pending' where importrequest_id = $uploadID";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	
	# remove any reference to this study from the (enrollment, study) tables
	# delete all series
	$sqlstring = "delete from mr_series where study_id = $studyid";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all studies
	$sqlstring = "delete from studies where study_id = $studyid";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	return 1;
}


# ----------------------------------------------------------
# --------- RearchiveSubject -------------------------------
# ----------------------------------------------------------
sub RearchiveSubject() {
	my ($id) = @_;
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	WriteLog("In DeleteSubject()");
	
	# get path info
	my $sqlstring = "select c.uid, a.study_num, b.project_id from studies a left join enrollment b on a.enrollment_id = b.enrollment_id left join subjects c on b.subject_id = c.subject_id where c.subject_id = $id";
	my $result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	my %row = $result->fetchhash;
	my $uid = $row{'uid'};
	my $projectRowID = $row{'project_id'};
	
	if (trim($uid) eq "") { return; }
	my $subjectpath = $cfg{'archivedir'} . "/$uid";
	
	# get instanceID
	$sqlstring = "select instance_id from projects where project_id = '$projectRowID'";
	$result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	%row = $result->fetchhash;
	my $instanceRowID = $row{'instance_id'};
	
	# create an import request, based on the current instance, project, and site & get next import ID
	$sqlstring = "insert into import_requests (import_datatype, import_datetime, import_status, import_equipment, import_siteid, import_projectid, import_instanceid, import_uuid, import_anonymize, import_permanent) values ('dicom',now(),'uploading','','','$projectRowID', '$instanceRowID', '','','')";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	my $uploadID = $result->insertid;
	my $outpath = $cfg{'uploadedpath'} . "/$uploadID";
	mkpath($outpath, { verbose => 1, mode => 0777 });
	
	# move all DICOM, par/rec, nifti files to the /dicomincoming directory
	# find all files in the /tmp dir and (anonymize,replace fields, rename, and dump to incoming)
	WriteLog("Calling find($subjectpath)");
	find(sub{MoveDICOMs($outpath);}, $subjectpath);
	
	# move the study directory to the deleted directory
	my $newpath = $cfg{'deletedpath'} . "/$uid-" . GenerateRandomString(10);
	mkpath($newpath, { verbose => 1, mode => 0777 });
	my $systemstring = "mv $subjectpath $newpath";
	WriteLog("Running $systemstring: [" . `$systemstring 2>&1` . "]");

	$sqlstring = "update import_requests set import_status = 'pending' where importrequest_id = $uploadID";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	
	# remove all database entries about this subject:
	# TABLES: subjects, subject_altuid, subject_relation, studies, *_series, enrollment, family_members, mostrecent
	$sqlstring = "delete from mostrecent where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	$sqlstring = "delete from family_members where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	$sqlstring = "delete from subject_relation where subjectid1 = $id or subjectid2 = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);

	$sqlstring = "delete from subject_altuid where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all series
	$sqlstring = "delete from mr_series where study_id in (select study_id from studies where enrollment_id in (select enrollment_id from enrollment where subject_id = $id))";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all studies
	$sqlstring = "delete from studies where enrollment_id in (select enrollment_id from enrollment where subject_id = $id)";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete all enrollments
	$sqlstring = "delete from enrollment where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
	
	# delete the subject
	$sqlstring = "delete from subjects where subject_id = $id";
	WriteLog($sqlstring);
	$result = $db->query($sqlstring) || SQLError($db->errmsg(),$sqlstring);
}


# ----------------------------------------------------------
# --------- MoveDICOMs -------------------------------------
# ----------------------------------------------------------
sub MoveDICOMs {
	my ($outdir) = @_;
	my $file = $File::Find::name;
	
	#WriteLog("In MoveDICOMs()");
	if (!-d $file) {
		#WriteLog("Checking $file");
		if (IsDICOMFile($file)) {
			# move the file to the incomingdir
			my $systemstring = "mv $file $outdir";
			WriteLog("Running $systemstring: [" . `$systemstring 2>&1` . "]");
		}
	}
}


# ----------------------------------------------------------
# --------- AnonymizeSeries --------------------------------
# ----------------------------------------------------------
sub AnonymizeSeries() {
	my ($fileioid,$data_id,$modality,$dicomtags) = @_;
	
	my @tags = split(';',$dicomtags);
	$db = Mysql->connect($cfg{'mysqlhost'}, $cfg{'mysqldatabase'}, $cfg{'mysqluser'}, $cfg{'mysqlpassword'}) || Error("Can NOT connect to $cfg{'mysqlhost'}\n");
	
	WriteLog("In AnonymizeSeries()");
	
	# build path to data
	my $sqlstring = "select a.*, b.*, e.uid from $modality" . "_series a left join studies b on a.study_id = b.study_id left join enrollment c on b.enrollment_id = c.enrollment_id left join subjects e on e.subject_id = c.subject_id left join fileio_requests f on f.data_id = a.$modality" . "series_id where f.fileiorequest_id = $fileioid";
	WriteLog("$sqlstring");
	my $result = $db->query($sqlstring) || SQLError($sqlstring, $db->errmsg());
	my %row = $result->fetchhash;
	my $uid = $row{'uid'};
	my $datatype = $row{'data_type'};
	my $studynum = $row{'study_num'};
	my $seriesnum = $row{'series_num'};
	
	my $indir = "$cfg{'archivedir'}/$uid/$studynum/$seriesnum/$datatype";
	WriteLog("Working on [$indir]");
	
	# find all dicom files
	chdir($indir);
	my @files = <*.dcm>;
	
	# anonymize the files
	foreach my $f(@files) {
		my $systemstring = "GDCM_RESOURCES_PATH=$cfg{'scriptdir'}/gdcm/Source/InformationObjectDefinition; export GDCM_RESOURCES_PATH; $cfg{'scriptdir'}/./gdcmanon -V --dumb -i $f";
		foreach my $tag(@tags) {
			$tag = trim($tag);
			$systemstring .= " --replace $tag";
		}
		$systemstring .= " -o $f";
		WriteLog("Anonymizing (" . `$systemstring  2>&1` . ")");
		#WriteLog("Anonymizing ($systemstring)");
	}
}