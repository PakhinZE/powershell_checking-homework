$assignment_location = Convert-Path 'C:\Users\DevC\Downloads\Ass 7.1\'
$result_location = Convert-Path 'C:\Users\DevC\Documents\Ass 7.1\'
$input_text_name = 'score.txt'
$stopwatch = [System.Diagnostics.Stopwatch]::new()

Get-ChildItem -Exclude $input_text_name $assignment_location | ForEach-Object -Process {
	$student_id = ($_.Name -split '_', 5)[1]
	$input_file_name = ($_.Name -split '_', 5)[4]
	$input_file_path = "$_"
	$temp_file_name = "$student_id" + '.cpp'
	$temp_file_path = Join-Path -Path $assignment_location -ChildPath $temp_file_name
	$output_file_name = "$student_id" + '.exe'
	$output_file_path = Join-Path -Path $assignment_location -ChildPath $output_file_name
	$result_file_name = "$student_id" + '.txt'
	$result_file_path = Join-Path -Path $result_location -ChildPath $result_file_name
	
	'*********************START*************************' >> $result_file_path
	"File name: $input_file_name" >> "$result_file_path"
	"Student ID: $student_id" >> "$result_file_path"

	'____________________file_content______________________' >> "$result_file_path"
	Get-Content $input_file_path >> "$result_file_path"
	Get-Content $input_file_path >> "$temp_file_path"
	'____________________file_content______________________' >> "$result_file_path"
	
	'____________________test_content______________________' >> "$result_file_path"
	$compile_error = & 'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\bin\g++.exe' `
		$temp_file_path `
		-o $output_file_path `
		-w `
		-I'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\include' `
		-I'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\x86_64-w64-mingw32\include' `
		-I'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\lib\gcc\x86_64-w64-mingw32\9.2.0\include' `
		-I'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\lib\gcc\x86_64-w64-mingw32\9.2.0\include\c++' `
		-L'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\lib'	 `
		-L'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\x86_64-w64-mingw32\lib' -static-libgcc 2>&1
	Remove-Item $temp_file_path
	if ($compile_error -eq $null) {
		$job = Start-Job -WorkingDirectory $assignment_location -ScriptBlock {
			& "$using:output_file_path"
		}
		$job_completed = $false
		if ($job.State -eq 'Completed') {
			$job_completed = $true
		}
		else {
			$stopwatch.Start()
			while ($stopwatch.Elapsed.Minutes -lt 1) {
				if ($job.State -eq 'Completed') {
					break 
				}
			}
			$stopwatch.Reset()
			if ($job.State -eq 'Completed') {
				$job_completed = $true
			}
			else {
				Stop-Job -Job $job
				$job_completed = $false
			}
		}
		if ($job_completed) {
			"//////////////////// Test Case `-`-`-`| terminal `|`-`-`-" >> "$result_file_path"
			$result = Receive-Job -Job $job
			"Test Case       : " + $test_case >> "$result_file_path"
            "Result          : " + ($result -join "`n                  ") >> "$result_file_path"
            "Expected Result : " + ($pass_case -join "`n                  ") >> "$result_file_path"
			"\\\\\\\\\\\\\\\\\\\\ Pass Case `-`-`-`| terminal `|`-`-`-" >> "$result_file_path"
			Get-ChildItem -Exclude $input_text_name -Include "*.txt" (Join-Path -Path $assignment_location -ChildPath '*') | ForEach-Object -Process {
				$txt_path = $_.FullName
				"//////////////////// Test Case `-`-`-`| $txt_path `|`-`-`-" >> "$result_file_path"
				Get-Content $txt_path >> "$result_file_path"
				"\\\\\\\\\\\\\\\\\\\\ Pass Case `-`-`-`| $txt_path `|`-`-`-" >> "$result_file_path"
				Remove-Item $txt_path
			}
		}
		else {
			"!!! Exception !!!" >> "$result_file_path"
		}
		Remove-Job -Force -Job $job
		Remove-Item $output_file_path
	} 
	else {
		"!! Compile Error !!" >> "$result_file_path"
	}
	'____________________test_content______________________' >> "$result_file_path"
	"**********************END**************************" >> "$result_file_path" }
