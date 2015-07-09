<<<<<<< HEAD
<?
 // ------------------------------------------------------------------------------
 // NiDB system.php
 // Copyright (C) 2004 - 2015
 // Gregory A Book <gregory.book@hhchealth.org> <gbook@gbook.org>
 // Olin Neuropsychiatry Research Center, Hartford Hospital
 // ------------------------------------------------------------------------------
 // GPLv3 License:

 // This program is free software: you can redistribute it and/or modify
 // it under the terms of the GNU General Public License as published by
 // the Free Software Foundation, either version 3 of the License, or
 // (at your option) any later version.

 // This program is distributed in the hope that it will be useful,
 // but WITHOUT ANY WARRANTY; without even the implied warranty of
 // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 // GNU General Public License for more details.

 // You should have received a copy of the GNU General Public License
 // along with this program.  If not, see <http://www.gnu.org/licenses/>.
 // ------------------------------------------------------------------------------
	require_once "Mail.php";
	require_once "Mail/mime.php";

	session_start();
?>

<html>
	<head>
		<link rel="icon" type="image/png" href="images/squirrel.png">
		<title>NiDB - System</title>
	</head>

<body>
	<div id="wrapper">
<?
	require "functions.php";
	require "includes.php";
	require "menu.php";
?>

<?
	/* ----- setup variables ----- */
	$action = GetVariable("action");
	
	/* determine action */
	if ($action == "") {
		DisplaySystem();
	}
	else {
		DisplaySystem();
	}
	
	
	/* ------------------------------------ functions ------------------------------------ */

	
	/* -------------------------------------------- */
	/* ------- DisplaySystem ---------------------- */
	/* -------------------------------------------- */
	function DisplaySystem() {
	
		$urllist['System'] = "system.php";
		NavigationBar("System", $urllist);

		$dbconnect = true;
		$devdbconnect = true;
		$L = mysqli_connect($GLOBALS['cfg']['mysqlhost'],$GLOBALS['cfg']['mysqluser'],$GLOBALS['cfg']['mysqlpassword'],$GLOBALS['cfg']['mysqldatabase']) or $dbconnect = false;
		$Ldev = mysqli_connect($GLOBALS['cfg']['mysqldevhost'],$GLOBALS['cfg']['mysqldevuser'],$GLOBALS['cfg']['mysqldevpassword'],$GLOBALS['cfg']['mysqldevdatabase']) or $devdbconnect = false;
		
		//echo "<pre>";
		//print_r($GLOBALS['cfg']);
		//echo "</pre>";
		
		?>
		<form name="configform" method="post" action="system.php">
		<input type="hidden" name="action" value="updateconfig">
		<table class="entrytable">
			<thead>
				<tr>
					<th>Variable</th>
					<th>Value</th>
					<th>Valid?</th>
					<th>Description</th>
				</tr>
			</thead>
			<tr>
				<td colspan="4" class="heading">Database</td>
			</tr>
			<tr>
				<td class="variable">mysqlhost</td>
				<td><input type="text" name="mysqlhost" value="<?=$GLOBALS['cfg']['mysqlhost']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database hostname (should be localhost or 127.0.0.0 unless the database is running a different server from the website)</td>
			</tr>
			<tr>
				<td class="variable">mysqluser</td>
				<td><input type="text" name="mysqluser" value="<?=$GLOBALS['cfg']['mysqluser']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database username</td>
			</tr>
			<tr>
				<td class="variable">mysqlpassword</td>
				<td><input type="password" name="mysqlpassword" value="<?=$GLOBALS['cfg']['mysqlpassword']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database password</td>
			</tr>
			<tr>
				<td class="variable">mysqldatabase</td>
				<td><input type="text" name="mysqldatabase" value="<?=$GLOBALS['cfg']['mysqldatabase']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>database (should be <tt>nidb</tt>)</td>
			</tr>
			<!--
			<tr>
				<td class="label">mysqlhost</td>
				<td><input type="text" name="mysqlhost" value="<?=$GLOBALS['cfg']['mysqlhost']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Development (testing) database hostname. This database will only be used if the website is accessed from port 8080 instead of 80 (example: http://localhost:8080)</td>
			</tr>
			<tr>
				<td class="label">mysqluser</td>
				<td><input type="text" name="mysqluser" value="<?=$GLOBALS['cfg']['mysqluser']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database username</td>
			</tr>
			<tr>
				<td class="label">mysqlpassword</td>
				<td><input type="password" name="mysqlpassword" value="<?=$GLOBALS['cfg']['mysqlpassword']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database password</td>
			</tr>
			<tr>
				<td class="label">mysqldatabase</td>
				<td><input type="text" name="mysqldatabase" value="<?=$GLOBALS['cfg']['mysqldatabase']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>database (should be <tt>nidb</tt>)</td>
			</tr>
			-->
			<tr>
				<td colspan="4" class="heading">Email</td>
			</tr>
			<tr>
				<td class="variable">emailusername</td>
				<td><input type="text" name="emailusername" value="<?=$GLOBALS['cfg']['emailusername']?>" size="45"></td>
				<td></td>
				<td>Username to login to the gmail account. Used for sending emails only</td>
			</tr>
			<tr>
				<td class="variable">emailpassword</td>
				<td><input type="password" name="emailpassword" value="<?=$GLOBALS['cfg']['emailpassword']?>" size="45"></td>
				<td></td>
				<td>email account password</td>
			</tr>
			<tr>
				<td class="variable">emailserver</td>
				<td><input type="text" name="emailserver" value="<?=$GLOBALS['cfg']['emailserver']?>" size="45"></td>
				<td></td>
				<td>Email server for sending email. For gmail, it should be <tt>smtp.gmail.com</tt></td>
			</tr>
			<tr>
				<td class="variable">emailport</td>
				<td><input type="text" name="emailport" value="<?=$GLOBALS['cfg']['emailport']?>" size="45"></td>
				<td></td>
				<td>Email server port. For gmail, it should be <tt>587</tt></td>
			</tr>
			<tr>
				<td class="variable">emailfrom</td>
				<td><input type="text" name="emailfrom" value="<?=$GLOBALS['cfg']['emailfrom']?>" size="45"></td>
				<td></td>
				<td>Email return address</td>
			</tr>
			<tr>
				<td colspan="4" class="heading">Misc.</td>
			</tr>
			<tr>
				<td class="variable">adminemail</td>
				<td><input type="email" name="adminemail" value="<?=$GLOBALS['cfg']['adminemail']?>" size="45"></td>
				<td></td>
				<td>Administrator's email. Displayed for error messages and other system activities</td>
			</tr>
			<tr>
				<td class="variable">siteurl</td>
				<td><input type="url" name="siteurl" value="<?=$GLOBALS['cfg']['siteurl']?>" size="45"></td>
				<td></td>
				<td>Full URL of the NiDB website</td>
			</tr>
			<tr>
				<td class="variable">usecluster</td>
				<td><input type="text" name="usecluster" value="<?=$GLOBALS['cfg']['usecluster']?>" size="45"></td>
				<td></td>
				<td>Use a cluster to perform QC. 1 for yes, 0 for no</td>
			</tr>
			<tr>
				<td class="variable">queuename</td>
				<td><input type="text" name="queuename" value="<?=$GLOBALS['cfg']['queuename']?>" size="45"></td>
				<td></td>
				<td>Cluster queue name</td>
			</tr>
			<tr>
				<td class="variable">queueuser</td>
				<td><input type="text" name="queueuser" value="<?=$GLOBALS['cfg']['queueuser']?>" size="45"></td>
				<td></td>
				<td>Linux username under which the QC cluster jobs are submitted</td>
			</tr>
			<tr>
				<td class="variable">clustersubmithost</td>
				<td><input type="text" name="clustersubmithost" value="<?=$GLOBALS['cfg']['clustersubmithost']?>" size="45"></td>
				<td></td>
				<td>Hostname which QC jobs are submitted</td>
			</tr>
			<tr>
				<td class="variable">qsubpath</td>
				<td><input type="text" name="qsubpath" value="<?=$GLOBALS['cfg']['qsubpath']?>" size="45"></td>
				<td></td>
				<td>Path to the qsub program. Use a full path to the executable, or just qsub if its already in the PATH environment variable</td>
			</tr>
			<tr>
				<td class="variable">version</td>
				<td><input type="text" name="version" value="<?=$GLOBALS['cfg']['version']?>" size="45"></td>
				<td></td>
				<td>NiDB version. No need to change this</td>
			</tr>
			<tr>
				<td class="variable">sitename</td>
				<td><input type="text" name="sitename" value="<?=$GLOBALS['cfg']['sitename']?>" size="45"></td>
				<td></td>
				<td>Displayed on NiDB main page and some email notifications</td>
			</tr>
			<tr>
				<td class="variable">sitenamedev</td>
				<td><input type="text" name="sitenamedev" value="<?=$GLOBALS['cfg']['sitenamedev']?>" size="45"></td>
				<td></td>
				<td>Development site name</td>
			</tr>
			<tr>
				<td class="variable">ispublic</td>
				<td><input type="text" name="ispublic" value="<?=$GLOBALS['cfg']['ispublic']?>" size="45"></td>
				<td></td>
				<td>Either a 1 or 0. If this installation of NiDB is on a public server and only has port 80 open, set this to 1.</td>
			</tr>
			<tr>
				<td class="variable">sitetype</td>
				<td><input type="text" name="sitetype" value="<?=$GLOBALS['cfg']['sitetype']?>" size="45"></td>
				<td></td>
				<td>Options are 'local'</td>
			</tr>
			<tr>
				<td class="variable">localftphostname</td>
				<td><input type="text" name="localftphostname" value="<?=$GLOBALS['cfg']['localftphostname']?>" size="45"></td>
				<td></td>
				<td>If you allow data to be sent to the local FTP and have configured the FTP site, this will be the information displayed to users on how to access the FTP site.</td>
			</tr>
			<tr>
				<td class="variable">localftpusername</td>
				<td><input type="text" name="localftpusername" value="<?=$GLOBALS['cfg']['localftpusername']?>" size="45"></td>
				<td></td>
				<td>Username for the locall access FTP account</td>
			</tr>
			<tr>
				<td class="variable">localftppassword</td>
				<td><input type="text" name="localftppassword" value="<?=$GLOBALS['cfg']['localftppassword']?>" size="45"></td>
				<td></td>
				<td>Password for local access FTP account. This is displayed to the users in clear text.</td>
			</tr>
			<tr>
				<td class="variable">debug</td>
				<td><input type="text" name="debug" value="<?=$GLOBALS['cfg']['debug']?>" size="45"></td>
				<td></td>
				<td>Enable debugging. 1 for yes, 0 for no</td>
			</tr>
			<tr>
				<td colspan="4" class="heading">Directories</td>
			</tr>
			<tr>
				<td class="variable">analysisdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['analysisdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['analysisdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Pipeline analysis directory</td>
			</tr>
			<tr>
				<td class="variable">groupanalysisdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['groupanalysisdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['groupanalysisdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Pipeline directory for group analyses</td>
			</tr>
			<tr>
				<td class="variable">archivedir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['archivedir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['archivedir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory for archived data. All binary data is stored in this directory.</td>
			</tr>
			<tr>
				<td class="variable">backupdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['backupdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['backupdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>All data is copied to this directory at the same time it is added to the archive directory. This can be useful if you want to use a tape backup and only copy out newer files from this directory to fill up a tape.</td>
			</tr>
			<tr>
				<td class="variable">ftpdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['ftpdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['ftpdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Downloaded data to be retreived by FTP is stored here</td>
			</tr>
			<tr>
				<td class="variable">importdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['importdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['importdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>No description available</td>
			</tr>
			<tr>
				<td class="variable">incomingdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['incomingdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['incomingdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>All data received from the DICOM receiver is placed in the root of this directory. All non-DICOM data is stored in numbered sub-directories of this directory.</td>
			</tr>
			<tr>
				<td class="variable">incoming2dir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['incoming2dir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['incoming2dir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>No description available</td>
			</tr>
			<tr>
				<td class="variable">lockdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['lockdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['lockdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Lock directory for the programs</td>
			</tr>
			<tr>
				<td class="variable">logdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['logdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['logdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Log directory for the programs</td>
			</tr>
			<tr>
				<td class="variable">mountdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['mountdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['mountdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory in which user data directories are mounted and any directories which should be accessible from the NFS mount export option of the Search page. For example, if the user enters [/home/user1/data/testing] the mountdir will be prepended to point to the real mount point of [/mount/home/user1/data/testing]. This prevents users from writing data to the OS directories.</td>
			</tr>
			<tr>
				<td class="variable">packageimportdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['packageimportdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['packageimportdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>If using the data package export/import feature, packages to be imported should be placed here</td>
			</tr>
			<tr>
				<td class="variable">qcmoduledir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['qcmoduledir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['qcmoduledir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory containing QC modules. Usually a subdirectory of the programs directory</td>
			</tr>
			<tr>
				<td class="variable">problemdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['problemdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['problemdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Files which encounter problems during import/archiving are placed here</td>
			</tr>
			<tr>
				<td class="variable">scriptdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['scriptdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['scriptdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory in which the Perl programs reside.</td>
			</tr>
			<tr>
				<td class="variable">webdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['webdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['webdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Root directory of the website</td>
			</tr>
			<tr>
				<td class="variable">downloadpath</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['downloadpath']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['downloadpath'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory which stores downloads available from the website</td>
			</tr>
			<tr>
				<td class="variable">uploadedpath</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['uploadedpath']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['uploadedpath'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Data received from the api.php and import pages is placed here</td>
			</tr>
			<tr>
				<td class="variable">tmpdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['tmpdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['tmpdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory used for temporary operations. Depending upon data sizes requested or processed, this directory may get very large, and may need to be outside of the OS drive.</td>
			</tr>
			<tr>
				<td class="variable">deletedpath</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['deletedpath']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['deletedpath'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Data is not usually deleted. It may be removed from the database and not appear on the website, but the data will end up in this directory.</td>
			</tr>
			
			
			<tr>
				<td colspan="3">
					<input type="submit" value="Update nidb.cfg">
				</td>
			</tr>
		</table>
		</form>

		Crontab<br>
		<pre><? echo system("crontab -l"); ?></pre>
		<?
	}
?>


<? include("footer.php") ?>
=======
<?
 // ------------------------------------------------------------------------------
 // NiDB system.php
 // Copyright (C) 2004 - 2015
 // Gregory A Book <gregory.book@hhchealth.org> <gbook@gbook.org>
 // Olin Neuropsychiatry Research Center, Hartford Hospital
 // ------------------------------------------------------------------------------
 // GPLv3 License:

 // This program is free software: you can redistribute it and/or modify
 // it under the terms of the GNU General Public License as published by
 // the Free Software Foundation, either version 3 of the License, or
 // (at your option) any later version.

 // This program is distributed in the hope that it will be useful,
 // but WITHOUT ANY WARRANTY; without even the implied warranty of
 // MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 // GNU General Public License for more details.

 // You should have received a copy of the GNU General Public License
 // along with this program.  If not, see <http://www.gnu.org/licenses/>.
 // ------------------------------------------------------------------------------
	require_once "Mail.php";
	require_once "Mail/mime.php";

	session_start();
?>

<html>
	<head>
		<link rel="icon" type="image/png" href="images/squirrel.png">
		<title>NiDB - System</title>
	</head>

<body>
	<div id="wrapper">
<?
	require "functions.php";
	require "includes.php";
	require "menu.php";
?>

<?
	/* ----- setup variables ----- */
	$action = GetVariable("action");
	
	/* determine action */
	if ($action == "") {
		DisplaySystem();
	}
	else {
		DisplaySystem();
	}
	
	
	/* ------------------------------------ functions ------------------------------------ */

	
	/* -------------------------------------------- */
	/* ------- DisplaySystem ---------------------- */
	/* -------------------------------------------- */
	function DisplaySystem() {
	
		$urllist['System'] = "system.php";
		NavigationBar("System", $urllist);

		$dbconnect = true;
		$devdbconnect = true;
		$L = mysqli_connect($GLOBALS['cfg']['mysqlhost'],$GLOBALS['cfg']['mysqluser'],$GLOBALS['cfg']['mysqlpassword'],$GLOBALS['cfg']['mysqldatabase']) or $dbconnect = false;
		$Ldev = mysqli_connect($GLOBALS['cfg']['mysqldevhost'],$GLOBALS['cfg']['mysqldevuser'],$GLOBALS['cfg']['mysqldevpassword'],$GLOBALS['cfg']['mysqldevdatabase']) or $devdbconnect = false;
		
		//echo "<pre>";
		//print_r($GLOBALS['cfg']);
		//echo "</pre>";
		
		?>
		<form name="configform" method="post" action="system.php">
		<input type="hidden" name="action" value="updateconfig">
		<table class="entrytable">
			<thead>
				<tr>
					<th>Variable</th>
					<th>Value</th>
					<th>Valid?</th>
					<th>Description</th>
				</tr>
			</thead>
			<tr>
				<td colspan="4" class="heading">Database</td>
			</tr>
			<tr>
				<td class="variable">mysqlhost</td>
				<td><input type="text" name="mysqlhost" value="<?=$GLOBALS['cfg']['mysqlhost']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database hostname (should be localhost or 127.0.0.0 unless the database is running a different server from the website)</td>
			</tr>
			<tr>
				<td class="variable">mysqluser</td>
				<td><input type="text" name="mysqluser" value="<?=$GLOBALS['cfg']['mysqluser']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database username</td>
			</tr>
			<tr>
				<td class="variable">mysqlpassword</td>
				<td><input type="password" name="mysqlpassword" value="<?=$GLOBALS['cfg']['mysqlpassword']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database password</td>
			</tr>
			<tr>
				<td class="variable">mysqldatabase</td>
				<td><input type="text" name="mysqldatabase" value="<?=$GLOBALS['cfg']['mysqldatabase']?>" size="45"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>database (should be <tt>nidb</tt>)</td>
			</tr>
			<!--
			<tr>
				<td class="label">mysqlhost</td>
				<td><input type="text" name="mysqlhost" value="<?=$GLOBALS['cfg']['mysqlhost']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Development (testing) database hostname. This database will only be used if the website is accessed from port 8080 instead of 80 (example: http://localhost:8080)</td>
			</tr>
			<tr>
				<td class="label">mysqluser</td>
				<td><input type="text" name="mysqluser" value="<?=$GLOBALS['cfg']['mysqluser']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database username</td>
			</tr>
			<tr>
				<td class="label">mysqlpassword</td>
				<td><input type="password" name="mysqlpassword" value="<?=$GLOBALS['cfg']['mysqlpassword']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Database password</td>
			</tr>
			<tr>
				<td class="label">mysqldatabase</td>
				<td><input type="text" name="mysqldatabase" value="<?=$GLOBALS['cfg']['mysqldatabase']?>"></td>
				<td><? if ($dbconnect) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>database (should be <tt>nidb</tt>)</td>
			</tr>
			-->
			<tr>
				<td colspan="4" class="heading">Email</td>
			</tr>
			<tr>
				<td class="variable">emailusername</td>
				<td><input type="text" name="emailusername" value="<?=$GLOBALS['cfg']['emailusername']?>" size="45"></td>
				<td></td>
				<td>Username to login to the gmail account. Used for sending emails only</td>
			</tr>
			<tr>
				<td class="variable">emailpassword</td>
				<td><input type="password" name="emailpassword" value="<?=$GLOBALS['cfg']['emailpassword']?>" size="45"></td>
				<td></td>
				<td>email account password</td>
			</tr>
			<tr>
				<td class="variable">emailserver</td>
				<td><input type="text" name="emailserver" value="<?=$GLOBALS['cfg']['emailserver']?>" size="45"></td>
				<td></td>
				<td>Email server for sending email. For gmail, it should be <tt>smtp.gmail.com</tt></td>
			</tr>
			<tr>
				<td class="variable">emailport</td>
				<td><input type="text" name="emailport" value="<?=$GLOBALS['cfg']['emailport']?>" size="45"></td>
				<td></td>
				<td>Email server port. For gmail, it should be <tt>587</tt></td>
			</tr>
			<tr>
				<td class="variable">emailfrom</td>
				<td><input type="text" name="emailfrom" value="<?=$GLOBALS['cfg']['emailfrom']?>" size="45"></td>
				<td></td>
				<td>Email return address</td>
			</tr>
			<tr>
				<td colspan="4" class="heading">Misc.</td>
			</tr>
			<tr>
				<td class="variable">adminemail</td>
				<td><input type="email" name="adminemail" value="<?=$GLOBALS['cfg']['adminemail']?>" size="45"></td>
				<td></td>
				<td>Administrator's email. Displayed for error messages and other system activities</td>
			</tr>
			<tr>
				<td class="variable">siteurl</td>
				<td><input type="url" name="siteurl" value="<?=$GLOBALS['cfg']['siteurl']?>" size="45"></td>
				<td></td>
				<td>Full URL of the NiDB website</td>
			</tr>
			<tr>
				<td class="variable">usecluster</td>
				<td><input type="text" name="usecluster" value="<?=$GLOBALS['cfg']['usecluster']?>" size="45"></td>
				<td></td>
				<td>Use a cluster to perform QC. 1 for yes, 0 for no</td>
			</tr>
			<tr>
				<td class="variable">queuename</td>
				<td><input type="text" name="queuename" value="<?=$GLOBALS['cfg']['queuename']?>" size="45"></td>
				<td></td>
				<td>Cluster queue name</td>
			</tr>
			<tr>
				<td class="variable">queueuser</td>
				<td><input type="text" name="queueuser" value="<?=$GLOBALS['cfg']['queueuser']?>" size="45"></td>
				<td></td>
				<td>Linux username under which the QC cluster jobs are submitted</td>
			</tr>
			<tr>
				<td class="variable">clustersubmithost</td>
				<td><input type="text" name="clustersubmithost" value="<?=$GLOBALS['cfg']['clustersubmithost']?>" size="45"></td>
				<td></td>
				<td>Hostname which QC jobs are submitted</td>
			</tr>
			<tr>
				<td class="variable">qsubpath</td>
				<td><input type="text" name="qsubpath" value="<?=$GLOBALS['cfg']['qsubpath']?>" size="45"></td>
				<td></td>
				<td>Path to the qsub program. Use a full path to the executable, or just qsub if its already in the PATH environment variable</td>
			</tr>
			<tr>
				<td class="variable">version</td>
				<td><input type="text" name="version" value="<?=$GLOBALS['cfg']['version']?>" size="45"></td>
				<td></td>
				<td>NiDB version. No need to change this</td>
			</tr>
			<tr>
				<td class="variable">sitename</td>
				<td><input type="text" name="sitename" value="<?=$GLOBALS['cfg']['sitename']?>" size="45"></td>
				<td></td>
				<td>Displayed on NiDB main page and some email notifications</td>
			</tr>
			<tr>
				<td class="variable">sitenamedev</td>
				<td><input type="text" name="sitenamedev" value="<?=$GLOBALS['cfg']['sitenamedev']?>" size="45"></td>
				<td></td>
				<td>Development site name</td>
			</tr>
			<tr>
				<td class="variable">ispublic</td>
				<td><input type="text" name="ispublic" value="<?=$GLOBALS['cfg']['ispublic']?>" size="45"></td>
				<td></td>
				<td>Either a 1 or 0. If this installation of NiDB is on a public server and only has port 80 open, set this to 1.</td>
			</tr>
			<tr>
				<td class="variable">sitetype</td>
				<td><input type="text" name="sitetype" value="<?=$GLOBALS['cfg']['sitetype']?>" size="45"></td>
				<td></td>
				<td>Options are 'local'</td>
			</tr>
			<tr>
				<td class="variable">localftphostname</td>
				<td><input type="text" name="localftphostname" value="<?=$GLOBALS['cfg']['localftphostname']?>" size="45"></td>
				<td></td>
				<td>If you allow data to be sent to the local FTP and have configured the FTP site, this will be the information displayed to users on how to access the FTP site.</td>
			</tr>
			<tr>
				<td class="variable">localftpusername</td>
				<td><input type="text" name="localftpusername" value="<?=$GLOBALS['cfg']['localftpusername']?>" size="45"></td>
				<td></td>
				<td>Username for the locall access FTP account</td>
			</tr>
			<tr>
				<td class="variable">localftppassword</td>
				<td><input type="text" name="localftppassword" value="<?=$GLOBALS['cfg']['localftppassword']?>" size="45"></td>
				<td></td>
				<td>Password for local access FTP account. This is displayed to the users in clear text.</td>
			</tr>
			<tr>
				<td class="variable">debug</td>
				<td><input type="text" name="debug" value="<?=$GLOBALS['cfg']['debug']?>" size="45"></td>
				<td></td>
				<td>Enable debugging. 1 for yes, 0 for no</td>
			</tr>
			<tr>
				<td colspan="4" class="heading">Directories</td>
			</tr>
			<tr>
				<td class="variable">analysisdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['analysisdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['analysisdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Pipeline analysis directory</td>
			</tr>
			<tr>
				<td class="variable">groupanalysisdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['groupanalysisdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['groupanalysisdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Pipeline directory for group analyses</td>
			</tr>
			<tr>
				<td class="variable">archivedir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['archivedir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['archivedir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory for archived data. All binary data is stored in this directory.</td>
			</tr>
			<tr>
				<td class="variable">backupdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['backupdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['backupdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>All data is copied to this directory at the same time it is added to the archive directory. This can be useful if you want to use a tape backup and only copy out newer files from this directory to fill up a tape.</td>
			</tr>
			<tr>
				<td class="variable">ftpdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['ftpdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['ftpdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Downloaded data to be retreived by FTP is stored here</td>
			</tr>
			<tr>
				<td class="variable">importdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['importdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['importdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>No description available</td>
			</tr>
			<tr>
				<td class="variable">incomingdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['incomingdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['incomingdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>All data received from the DICOM receiver is placed in the root of this directory. All non-DICOM data is stored in numbered sub-directories of this directory.</td>
			</tr>
			<tr>
				<td class="variable">incoming2dir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['incoming2dir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['incoming2dir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>No description available</td>
			</tr>
			<tr>
				<td class="variable">lockdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['lockdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['lockdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Lock directory for the programs</td>
			</tr>
			<tr>
				<td class="variable">logdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['logdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['logdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Log directory for the programs</td>
			</tr>
			<tr>
				<td class="variable">mountdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['mountdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['mountdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory in which user data directories are mounted and any directories which should be accessible from the NFS mount export option of the Search page. For example, if the user enters [/home/user1/data/testing] the mountdir will be prepended to point to the real mount point of [/mount/home/user1/data/testing]. This prevents users from writing data to the OS directories.</td>
			</tr>
			<tr>
				<td class="variable">packageimportdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['packageimportdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['packageimportdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>If using the data package export/import feature, packages to be imported should be placed here</td>
			</tr>
			<tr>
				<td class="variable">qcmoduledir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['qcmoduledir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['qcmoduledir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory containing QC modules. Usually a subdirectory of the programs directory</td>
			</tr>
			<tr>
				<td class="variable">problemdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['problemdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['problemdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Files which encounter problems during import/archiving are placed here</td>
			</tr>
			<tr>
				<td class="variable">scriptdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['scriptdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['scriptdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory in which the Perl programs reside.</td>
			</tr>
			<tr>
				<td class="variable">webdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['webdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['webdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Root directory of the website</td>
			</tr>
			<tr>
				<td class="variable">downloadpath</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['downloadpath']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['downloadpath'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory which stores downloads available from the website</td>
			</tr>
			<tr>
				<td class="variable">uploadedpath</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['uploadedpath']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['uploadedpath'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Data received from the api.php and import pages is placed here</td>
			</tr>
			<tr>
				<td class="variable">tmpdir</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['tmpdir']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['tmpdir'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Directory used for temporary operations. Depending upon data sizes requested or processed, this directory may get very large, and may need to be outside of the OS drive.</td>
			</tr>
			<tr>
				<td class="variable">deletedpath</td>
				<td><input type="text" value="<?=$GLOBALS['cfg']['deletedpath']?>" size="45"></td>
				<td><? if (file_exists($GLOBALS['cfg']['deletedpath'])) { ?><span style="color:green">&#x2713;</span><? } else { ?><span style="color:red">&#x2717;</span><? } ?></td>
				<td>Data is not usually deleted. It may be removed from the database and not appear on the website, but the data will end up in this directory.</td>
			</tr>
			
			
			<tr>
				<td colspan="3">
					<input type="submit" value="Update nidb.cfg">
				</td>
			</tr>
		</table>
		</form>

		Crontab<br>
		<pre><? echo system("crontab -l"); ?></pre>
		<?
	}
?>


<? include("footer.php") ?>
>>>>>>> 7cc912bd4d9ca991eaf09b17355c0bf507a73aa9
