<?
 // ------------------------------------------------------------------------------
 // NiDB subject_inlineupdate.php
 // Copyright (C) 2004 - 2014
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
	session_start();

	require "functions.php";
	
	if (isset($_POST['element_id'])) {
		/* database connection */
		$link = mysql_connect($GLOBALS['cfg']['mysqlhost'],$GLOBALS['cfg']['mysqluser'],$GLOBALS['cfg']['mysqlpassword']) or die ("Could not connect: " . mysql_error());
		mysql_select_db($GLOBALS['cfg']['mysqldatabase']) or die ("Could not select database<br>");

		$id = $_POST['id'];
		$modality = strtolower($_POST['modality']);
		$field = $_POST['element_id'];
		$value = mysql_real_escape_string($_POST['update_value']);
		$sqlstring = "update subjects set $field = '$value' where subject_id = $id";
		$result = mysql_query($sqlstring) or die("Query failed: " . mysql_error() . "<br><i>$sqlstring</i><br>");
		if ($_POST['update_value'] == "") { $dispvalue = " "; } else { $dispvalue = $_POST['update_value']; }
		echo str_replace('\n',"<br>",$dispvalue);
	}
?>