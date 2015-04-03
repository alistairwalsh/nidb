<?
 // ------------------------------------------------------------------------------
 // NiDB adminqc.php
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
?>

<html>
	<head>
		<link rel="icon" type="image/png" href="images/squirrel.png">
		<title>NiDB - Manage QC Modules</title>
	</head>

<body>
	<div id="wrapper">
<?
	//require "config.php";
	require "functions.php";
	require "includes.php";
	require "nidbapi.php";
	require "menu.php";

	/* ----- setup variables ----- */
	$action = GetVariable("action");
	$id = GetVariable("id");
	$modulename = GetVariable("modulename");
	$modality = GetVariable("modality");
	
	/* determine action */
	switch ($action) {
		case 'addmodule':
			AddQCModule($modulename,$modality);
			DisplayQCModuleList();
			break;
		case 'disable':
			DisableQCModule($id);
			DisplayQCModuleList();
			break;
		case 'enable':
			EnableQCModule($id);
			DisplayQCModuleList();
			break;
		case 'reset':
			ResetQCModule($id);
			DisplayQCModuleList();
			break;
		default:
			DisplayQCModuleList();
	}
	
	
	/* ------------------------------------ functions ------------------------------------ */


	/* -------------------------------------------- */
	/* ------- UpdateQCModule ---------------------- */
	/* -------------------------------------------- */
	function UpdateQCModule($id, $qcmname, $modalitydesc, $admin) {
		/* perform data checks */
		$qcmname = mysql_real_escape_string($qcmname);
		$modalitydesc = mysql_real_escape_string($modalitydesc);
		
		/* update the modality */
		$sqlstring = "update qc_modules set qcm_name = '$qcmname', modality_desc = '$modalitydesc', modality_admin = '$admin' where modality_id = $id";
		$result = mysql_query($sqlstring) or die("Query failed: " . mysql_error() . "<br><i>$sqlstring</i><br>");
		
		?><div align="center"><span class="message"><?=$qcmname?> updated</span></div><br><br><?
	}


	/* -------------------------------------------- */
	/* ------- AddQCmodule ------------------------ */
	/* -------------------------------------------- */
	function AddQCmodule($modulename,$modality) {
		/* perform data checks */
		$modulename = mysql_real_escape_string($modulename);
		$modality = mysql_real_escape_string($modality);
		
		/* insert the new modality */
		$sqlstring = "insert into qc_modules (qcm_name, qcm_modality) values ('$modulename', '$modality')";
		$result = mysql_query($sqlstring) or die("Query failed: " . mysql_error() . "<br><i>$sqlstring</i><br>");
		
		?><div align="center"><span class="message"><?=$modulename?> added</span></div><br><br><?
	}

	
	/* -------------------------------------------- */
	/* ------- EnableQCModule --------------------- */
	/* -------------------------------------------- */
	function EnableQCModule($id) {
		$sqlstring = "update qc_modules set qcm_isenabled = 1 where qcmodule_id = $id";
		$result = mysql_query($sqlstring) or die("Query failed: " . mysql_error() . "<br><i>$sqlstring</i><br>");
	}


	/* -------------------------------------------- */
	/* ------- DisableQCModule -------------------- */
	/* -------------------------------------------- */
	function DisableQCModule($id) {
		$sqlstring = "update qc_modules set qcm_isenabled = 0 where qcmodule_id = $id";
		$result = mysql_query($sqlstring) or die("Query failed: " . mysql_error() . "<br><i>$sqlstring</i><br>");
	}

	
	/* -------------------------------------------- */
	/* ------- DisplayQCModuleList ---------------- */
	/* -------------------------------------------- */
	function DisplayQCModuleList() {
	
		$urllist['Administration'] = "admin.php";
		$urllist['QC Modules'] = "adminqc.php";
		NavigationBar("Admin", $urllist);
		
	?>

	<table class="graydisplaytable">
		<thead>
			<tr>
				<th>Module name</th>
				<th>Modality</th>
				<th>Enable/Disable</th>
			</tr>
		</thead>
		<tbody>
			<form action="adminqc.php" method="post">
			<input type="hidden" name="action" value="addmodule">
			<tr>
				<td><input type="text" name="modulename"></td>
				<td>
					<select name="modality">
					<?
						$modalities = NIDB\GetModalityList();
						foreach ($modalities as $modality) {
							?><option value="<?=$modality?>"><?=$modality?></option><?
						}
					?>
					</select>
				</td>
				<td><input type="submit" value="Add"></td>
				</form>
			</tr>
			<?
				$sqlstring = "select * from qc_modules order by qcm_name";
				$result = mysql_query($sqlstring) or die("Query failed: " . mysql_error() . "<br><i>$sqlstring</i><br>");
				while ($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
					$id = $row['qcmodule_id'];
					$modality = $row['qcm_modality'];
					$name = $row['qcm_name'];
					$enabled = $row['qcm_isenabled'];

					/* calculate the status color */
					if (!$enabled) { $color = "gray"; }
					else { $color = "darkblue"; }

					?>
					<tr style="color: <?=$color?>">
						<td><?=$name?></td>
						<td><?=$modality?></td>
						<td>
							<?
								if ($enabled) {
									?><a href="adminqc.php?action=disable&id=<?=$id?>"><img src="images/checkedbox16.png"></a><?
								}
								else {
									?><a href="adminqc.php?action=enable&id=<?=$id?>"><img src="images/uncheckedbox16.png"></a><?
								}
							?>
						</td>
					</tr>
					<? 
				}
			?>
		</tbody>
	</table>
	<?
	}
?>


<? include("footer.php") ?>