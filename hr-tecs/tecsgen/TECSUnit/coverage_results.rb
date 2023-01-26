require 'json'

function_array = [] #テスト対象の関数名を格納
file_array = [] #テスト対象を含むファイル名を格納
coverage_func_array = [] #コードカバレッジの結果を格納（Function）
coverage_file_array = [] #コードカバレッジの結果を格納（File）
coverage_func_count = 0 #配列の要素番号（Function）
coverage_file_count = 0 #配列の要素番号（File）
output_count = 0 #最終的に表示するための配列output_arrayの要素番号
func_flag = nil #二行目を扱うためのフラグ（Function）
file_flag = nil #二行目を扱うためのフラグ（File）
output_array = [] #最終的に表示するための配列

#テスト対象となる関数名とファイル名をそれぞれ配列に格納
file1 = File.open("target.json")
test_case = JSON.load(file1)
for count in 1..test_case.length do
	target_num = "target"+count.to_s
	function_array[count-1] = "t"+test_case[target_num]["cell"]+"_"+test_case[target_num]["entry"]+"_"+test_case[target_num]["function"]
	if !file_array.include?("src/t"+test_case[target_num]["cell"]+".c")
		file_array[count-1] = "src/t"+test_case[target_num]["cell"]+".c"
	end
end
file1.close

#コードカバレッジ結果をFunctionとFileに識別
file2 = open("coverage_results.txt")
file2.each do |line|
	if func_flag == true
		coverage_func_array[coverage_func_count] = line.chomp
		coverage_func_count += 1
		func_flag = nil
	elsif file_flag == true
		coverage_file_array[coverage_file_count] = line.chomp
		coverage_file_count += 1
		file_flag = nil
	end
	if line.include?("Function ")
		coverage_func_array[coverage_func_count] = line.chomp
		coverage_func_count += 1
		func_flag = true
	elsif line.include?("File ")
		coverage_file_array[coverage_file_count] = line.chomp
		coverage_file_count += 1
		file_flag = true
	end
end
file2.close

#Functionに関するコードカバレッジの結果について不要なものを排除
for count in 1..coverage_func_array.length do
	for count2 in 1..function_array.length do
		if coverage_func_array[count-1].include?(function_array[count2-1])
			output_array[output_count] = coverage_func_array[count-1]
			output_count += 1
			output_array[output_count] = coverage_func_array[count]
			output_count += 1
			count += 1
			break
		end
	end
end

#Fileに関するコードカバレッジの結果について不要なものを排除
for count in 1..coverage_file_array.length do
	for count2 in 1..file_array.length do
		if coverage_file_array[count-1].include?(file_array[count2-1])
			output_array[output_count] = coverage_file_array[count-1]
			output_count += 1
			output_array[output_count] = coverage_file_array[count]
			output_count += 1
			count += 1
			break
		end
	end
end

puts output_array

