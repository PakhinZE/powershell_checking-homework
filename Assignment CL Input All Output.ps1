$assignment_location = Convert-Path 'C:\Users\oumwa\Downloads\Assignment 5.2\'
$result_location = Convert-Path 'C:\Users\oumwa\Documents\Assignment 5.2\'
$test_unit = [ordered]@{
	'input_2.txt y input_1.txt n' = @('Your square is not a magic square!! Try more <y/n>?', 
		'Congratulations!! Your square is a magic square.', 
		'The magic constant of this square is 15. Try more <y/n>?');
	'input_4.txt y input_3.txt n' = @('Your square is not a magic square!! Try more <y/n>?', 
		'Congratulations!! Your square is a magic square.', 
		'The magic constant of this square is 369. Try more <y/n>?')
}

$exclude = 'input_*.txt'
$stopwatch = [System.Diagnostics.Stopwatch]::new()

Get-ChildItem -Include '*.cpp' -Exclude $exclude (Join-Path -Path $assignment_location -ChildPath '*') | ForEach-Object -Process {
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
		-L'C:\Program Files (x86)\Embarcadero\Dev-Cpp\TDM-GCC-64\x86_64-w64-mingw32\lib' `
		-static-libgcc 2>&1
	Remove-Item $temp_file_path

	if ($compile_error -eq $null) {
		$test_unit.GetEnumerator() | ForEach-Object -Process {
			$test_case = $_.key	
			$pass_case = $_.value
			'////////////////////////////////////////////////////////////////////////////////' >> "$result_file_path"
			$job = Start-Job -WorkingDirectory $assignment_location -ScriptBlock {
				"$using:test_case" | & "$using:output_file_path"
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

			$list_out_text_file = Get-ChildItem -Include '*.txt' -Exclude $exclude (Join-Path -Path $assignment_location -ChildPath '*')
			if ($job_completed) {
				$result = (Receive-Job -Job $job)
				'Test Case       : ' + $test_case >> "$result_file_path"
				if ($list_out_text_file -eq $null) {
					'Result          : ' + ($result -join "`n                  ") >> "$result_file_path"
				}
				else {
					$list_out_text_file | ForEach-Object -Process {
						$text_path = $_.FullName
						$result_2 = $result + (Get-Content $text_path)
						'Result          : ' + ($result_2 -join "`n                  ") >> "$result_file_path"
					}
					Remove-Item $text_path
				}
				'Expected Result : ' + ($pass_case -join "`n                  ") >> "$result_file_path"
			}
			else {
				$list_out_text_file | Remove-Item
				'!!! Exception !!!' >> "$result_file_path"
			}
			Remove-Job -Force -Job $job
			'\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\' >> "$result_file_path"
			'' >> "$result_file_path"
		}
		Remove-Item $output_file_path
	} 
	else {
		'!! Compile Error !!' >> "$result_file_path"
	}
	'____________________test_content______________________' >> "$result_file_path"
	'**********************END**************************' >> "$result_file_path" 
}