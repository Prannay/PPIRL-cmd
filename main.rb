#!/usr/bin/env ruby

#class DbasesController
$clickable = Hash.new(0) # hash for clickable attribute values whose all chars are not '-'. Its binary
$clickcount = Hash.new(0) # hash for count of clickable attribute values whose all chars are not '-' -- actual k
#$nonclickable = Hash.new(0) # hash for count of nonclickable attribute values whose all chars are '-'
$unique = Hash.new(0)    # hash for unique attribute values, unique=1 means they will contribute to 100% privacy budget
$count = Hash.new(0)     # hash for count of attribute values
$counted = Hash.new(0)   # hash for count of unique attribute values, it will help in finding the total number of values contributing to 100% privacy budget
$partial = Hash.new(0)   # hash for partial values disclosed for unique attributes, partial=0/*no info disclosed*/ partial=1/*partial info disclosed*/ partial=2/*full info disclosed*/
$total = 0               # total number of unique attribute values contributing to 100% privacy budget
$budget = 100.0            # total budget initially assigned as 100%
$k = 5                   # default value of k
     
def make_counthash_finaldb
  @inputdb = []  # input database array of hash of attribute values
  @fdb = []  # final database array of hash of encrypted attribute values
  numrows_fdb = 0 # count of number of rows of @fdb
  puts "Please type the value of threshold 'k' of k-anonymity: "
  $k = gets.chomp
  puts "k is: #{$k} \n"
  puts "Please type separator/delimiter of your input csv/text file: "
  delimit = gets.chomp
  #puts "delimiter is: #{delimit} \n"
  File.foreach("test.csv").drop(1).each_slice(2) do |line|
    #puts "line0= " + line[0]
    #puts "line1= " + line[1]
    id1, fn1, ssn1, dob1 = line[0].strip.split(delimit)
    id2, fn2, ssn2, dob2 = line[1].strip.split(delimit)
    if(fn1 == NIL && ssn1 == NIL && dob1 == NIL && fn2 == NIL && ssn2 == NIL && dob2 == NIL)
      puts "Please type correct separator/delimiter of your input csv/text file: "
      delimit = gets.chomp
      redo
    end
    # Creating Input database
    inputhash = {:id=>id1, :fname=>fn1, :ssn=>ssn1, :dob=>dob1}
    @inputdb << inputhash
    inputhash = {:id=>id2, :fname=>fn2, :ssn=>ssn2, :dob=>dob2}
    @inputdb << inputhash
    # Counting the count of attribute values
    $count[fn1] += 1
    $count[fn2] += 1
    $count[ssn1] += 1 
    $count[ssn2] += 1
    $count[dob1] += 1
    $count[dob2] += 1
    $count[fn1+","+ssn1] += 1
    $count[fn2+","+ssn2] += 1
    $count[fn1+","+dob1] += 1
    $count[fn2+","+dob2] += 1
    $count[ssn1+","+dob1] += 1
    $count[ssn2+","+dob2] += 1
    
    # Calling compare function to compare two attr values and replace them with 'D for 1 difference, Diff for more than 2 differences, TX for transpose, M for missing values, - for same characters'
    #puts fn1 + " " + fn2
    ffname = compare(fn1, fn2, 1) #final first name, 1 for attribute = fname
    if(check_clickable(ffname))
      $clickable[fn1] = 1
      # add clickcount here itself instead of using nonclickable ans subtracting it from count
      $clickcount[fn1] += 1
      $clickable[fn2] = 1
      $clickcount[fn2] += 1
    else
      # if one instance of fn1 is clickable then keep it clickable for all other instances also
      if($clickable[fn1] != 1)
        $clickable[fn1] = 0 
        #$nonclickable[fn1] += 1 
      end
      if($clickable[fn2] != 1)
        $clickable[fn2] = 0
        #$nonclickable[fn2] += 1 
      end
    end
    #puts "ffname=  #{ffname}"
    #puts ssn1 + " " + ssn2
    fssn = compare(ssn1, ssn2, 2) #final ssn,  2 for attribute = ssn 
    if(check_clickable(fssn))
      if(fssn == "Diff") # As SSN cannot be disclosed, dont increase clickcount also
        $clickable[ssn1] = 0 
        $clickable[ssn2] = 0
      else
        $clickable[ssn1] = 1
        $clickable[ssn2] = 1
        $clickcount[ssn1] += 1
        $clickcount[ssn2] += 1
      end
    else
      # if one instance of ssn1 is clickable then keep it clickable for all other instances also
      if($clickable[ssn1] != 1)
        $clickable[ssn1] = 0 
        #$nonclickable[ssn1] += 1 
      end
      if($clickable[ssn2] != 1)
        $clickable[ssn2] = 0
        #$nonclickable[ssn2] += 1 
      end
    end
    puts "fssn=  #{fssn}"
    puts dob1 + " " + dob2
    fdob = compare(dob1, dob2, 3) #final dob,  3 for attribute = dob
    if(check_clickable(fdob))
      $clickable[dob1] = 1
      $clickcount[dob1] += 1
      $clickable[dob2] = 1
      $clickcount[dob2] += 1
    else
      if($clickable[dob1] != 1)
        $clickable[dob1] = 0 
        #$nonclickable[dob1] += 1 
      end
      if($clickable[dob2] != 1)
        $clickable[dob2] = 0
        #$nonclickable[dob2] += 1 
      end
    end
    #puts "fdob=  #{fdob}"
    
    numrows_fdb +=1
    hash = {:fid=>numrows_fdb, :ffname=>ffname, :fssn=>fssn, :fdob=>fdob}
    @fdb << hash 
  end #reading from input file

  # Printing input database which has attr values
  puts "\n# Printing input database which has attr values"
  for i in 0..(@inputdb.size-1)
    puts @inputdb[i][:id] + ": " + @inputdb[i][:fname] + ", " + @inputdb[i][:ssn] + ", " + @inputdb[i][:dob]
  end

  # Printing final database which has encrypted attr values
  puts "\n# Printing final database which has encrypted attr values"
  puts 'fname , fssn, fdob'
  for i in 0..(@fdb.size-1)
    puts @fdb[i][:fid].to_s + ": " + @fdb[i][:ffname] + ", " + @fdb[i][:fssn] + ", " + @fdb[i][:fdob]
  end

  check_anonymity(@inputdb, delimit)
  
end

def compare(one, two, attr) # try to check for edit distance also like ROXAN and ROAN should not be diff instead it should be D
  if(one.empty? || two.empty?)
    return 'M'
  end
  fvalue = ''
  l1 = one.length
  l2 = two.length
  max = l1
  if(l2 > l1)
    max = l2
  end
  count = 0
  flag = 0 ;
  index1 = index2 = index3 = index4 = -1
  for i in 0..max-1
    puts "^^^^^^^^^^^^i==== #{i}"
    if(one[i] == two[i])
      if(one[i] == '/')
        if(flag == 1)
          fvalue[i-2] = '/'
        else
          fvalue[i] = '/'
        end
      else
        if(flag == 1)
          fvalue[i-2] = '-'
        else
          fvalue[i] = '-'
        end
      end
    else
      count = count+1
      puts "count= #{count}"

      if(count == 1)
        fvalue[i] = 'D'
        index1 = i
        next
      elsif(count == 2)
        index2 = i
      elsif(count == 3 and attr == 3)
        index3 = i
      elsif(count == 4 and attr == 3)
        index4 = i
      else
        #puts "ELSE"
      end

      if(attr != 1 and count == 2 and index2 == index1+1 and one[index1] == two[index2] and one[index2] == two[index1])
        fvalue[index1] = 'T'
        fvalue[index2] = 'X'
      elsif(attr == 3 and count == 2 and index2 == index1+3)
        str1 = one[0] + one[1]
        str2 = one[3] + one[4]
        str3 = two[0] + two[1]
        str4 = two[3] + two[4] 
        if(str1 == str4 and str2 == str3)
          fvalue[0] = 'T'
          fvalue[1] = '/'
          fvalue[2] = 'X'
          flag = 1;
        else
          fvalue = 'Diff'
          return fvalue
        end
      elsif(attr == 3 and count < 4 and i < max-1)
        fvalue[i] = 'D'
        next 
      elsif(attr == 3 and count == 4 and index2 == index1+1 and index3 == index2+2 and index4 == index3+1 )
        str1 = one[index1] + one[index2]
        #puts str1
        str2 = one[index3] + one[index4]
        #puts str2
        str3 = two[index1] + two[index2]
        #puts str3
        str4 = two[index3] + two[index4]
        #puts str4
        if(str1 == str4 and str2 == str3)
          fvalue[0] = 'T'
          fvalue[1] = '/'
          fvalue[2] = 'X'
          flag = 1;
        end
      else
          fvalue = 'Diff'
          return fvalue
      end
    end
  end
  return fvalue
end

#if all characters in encrypted string are '-' then its not clickable otherwise clickable as it will have D/DIFF/TX
def check_clickable(str)
  if(str == "M")
    return false
  end
  for i in 0..(str.length-1)
    if(str[i] != '-')
      return true
    end 
  end
  return false
end

def check_anonymity(inputdb, delimit)
  # Printing input database which has attr values
  #for i in 0..(@inputdb.size-1)
  #  puts inputdb[i][:id] + ": " + inputdb[i][:fname] + ", " + inputdb[i][:ssn] + ", " + inputdb[i][:dob]
  #end
  for i in 0..(@inputdb.size-1)
    fn = @inputdb[i][:fname]
    ssn = @inputdb[i][:ssn]
    dob = @inputdb[i][:dob]
    $unique[fn] = check_unique($count[fn], $clickable[fn])
    $counted[fn] += 1
    if($unique[fn] == 1 and $counted[fn] == 1)
      $total += 1
    end
    $unique[ssn] = check_unique($count[ssn], $clickable[ssn])
    $counted[ssn] += 1
    if($unique[ssn] == 1 and $counted[ssn] == 1)
      $total += 1
    end
    $unique[dob] = check_unique($count[dob], $clickable[dob])
    $counted[dob] += 1
    if($unique[dob] == 1 and $counted[dob] == 1)
      $total += 1
    end
    $unique[fn + "," + ssn] = check_unique_combined($count[fn + "," + ssn], $unique[fn], $unique[ssn])
    $counted[fn + "," + ssn] += 1
    if($unique[fn + "," + ssn] == 1 and $counted[fn + "," + ssn] == 1)
      $total += 1
    end
    $unique[fn + "," + dob] = check_unique_combined($count[fn + "," + dob], $unique[fn], $unique[dob])
    $counted[fn + "," + dob] += 1
    if($unique[fn + "," + dob] == 1 and $counted[fn + "," + dob] == 1)
      $total += 1
    end
    $unique[ssn + "," + dob] = check_unique_combined($count[ssn + "," + dob], $unique[ssn], $unique[dob])
    $counted[ssn + "," + dob] += 1
    if($unique[ssn + "," + dob] == 1 and $counted[ssn + "," + dob] == 1)
      $total += 1
    end
  end 
  #puts "total= #{$total}"
end

def check_unique(count_str, isclickable)
  if(count_str < $k.to_i && isclickable == 1)
    return 1
  elsif(count_str > $k.to_i && isclickable == 1)
    return 0 
  else
    return -1 
  end
end

def check_unique_combined(count_str, unique1, unique2)
  if(unique1 == 0 && unique2 == 0 && count_str < $k.to_i)
    return 1
  else
    return -1
  end
end

def column(col, db)
  if db == "fdb"
    if(col == 1)
      return "ffname"
    elsif(col == 2)
      return "fssn"
    else
      return "fdob"
    end
  elsif db == "inputdb"
    if(col == 1)
      return "fname"
    elsif(col == 2)
      return "ssn"
    else
      return "dob"
    end 
  else
  end
end

def show_budget
  if($budget < 0)
    puts "BUDGET = 0\n"
  else  
    puts "BUDGET = #{$budget}\n"
  end
end

def partial_value(v, fv, str)
  if(str == "T/X")
    temp = v.dup
    temp[6] = '-'
    temp[7] = '-'
    temp[8] = '-'
    temp[9] = '-'
  
  else
    temp = fv.dup
    index = fv.index(str)
    temp[index] = v[index]
    if(str == "TX")
      temp[index+1] = v[index+1]
    end
  end
  return temp
end

def disclose(v, fv)
  if(fv.include?("TX"))
    pv = partial_value(v, fv, "TX")

  elsif(fv.include?("D"))
    pv = partial_value(v, fv, "D")
  
  elsif(fv.include?("T/X"))
    pv = partial_value(v, fv, "T/X")
  
  else

  end
  return pv
end

# calculates budget for value v, finalvalue fv in final db, column name col_inputdb
def budget_cal(v, fv, col_inputdb)
  if(fv == "M")
    puts "Missing Value\n"
  
  elsif(fv == "Diff" && $partial[v] == 0)
    if(col_inputdb == "ssn")
      puts "SSN cannot be disclosed\n"
    else
      if($unique[v] == 1)
        $budget = ($budget - ((100.0/$total) * (1.0/$clickcount[v]))).round(2)
      end
      $partial[v] = 2 
      puts "Attribute value = #{v}\n"
    end

  elsif(col_inputdb == "ssn" && (fv.include?("T") || fv.include?("D")) && $partial[v] == 0)
    if($unique[v] == 1)
      $budget = ($budget - ((100.0/$total) * (1.0/$clickcount[v]))).round(2)
    end
    $partial[v] = 2
    puts "Attribue value = #{disclose(v, fv)}\n" 
  
  elsif($partial[v] == 0)
    if($unique[v] == 1)
      $budget = ($budget - ((100.0/$total) * (0.5/$clickcount[v]))).round(2)
    end
    $partial[v] = 1
    puts "Attribue value = #{disclose(v, fv)}\n" 
         
  elsif($partial[v] == 1)
    if($unique[v] == 1)
      $budget = ($budget - ((100.0/$total) * (0.5/$clickcount[v]))).round(2)
    end
    $partial[v] = 2
    puts "Attribue value = #{v}\n" 
  
  else
    if(col_inputdb == "ssn")
      puts "SSN cannot be disclosed more than 2 digits\n"
    else
      puts "Attribute value #{v} has already been disclosed, please try another row or column \n"
    end
  end
          
  show_budget
end

# calling function
make_counthash_finaldb

# main function
if __FILE__ == $0
  puts "total= #{$total}"
  
  # Printing count of attr values
  puts "\n# Printing count of attr values"
  $count.each do |attr, number|
    puts "#{attr} => #{number}"
  end
    
  # Printing clickable of attr values
  puts "\n# Printing clickable attr values"
  $clickable.each do |attr, number|
    puts "#{attr} => #{number}"
  end
  
  # Printing unique attr values
  puts "\n# Printing unique attr values"
  $unique.each do |attr, number|
    puts "#{attr} => #{number}"
  end
  
  # Printing clickcount of clickable attr values
  puts "\n# Printing clickcount of clickable attr values"
  $clickcount.each do |attr, number|
    puts "#{attr} => #{number}"
  end

  while(1)
    puts "\nPlease enter c when you are done with entity resolution \n"
    puts "Otherwise enter row,column to be disclosed separated by comma: "
    input = gets.chomp
    if(input != "c")
      row_s, col_s = input.strip.split(",")
      row = row_s.to_i - 1
      col = col_s.to_i
      puts "row= #{row}\n"
      puts "col= #{col}\n"
      
      if(row < 0 || row > (@fdb.size()-1) || col < 1 || col > 3)
        puts "row or column number is incorrect, please enter valid row,column number\n"
        show_budget
        redo
      end
      
      col_fdb = column(col, "fdb")
      puts "col_fdb= #{col_fdb}\n"
      fv = @fdb[row][col_fdb.to_sym]
      puts "@fdb[row][col_fdb]= #{fv}\n"
      
      if(check_clickable(fv))
        # main logic of privacy budget
        puts "# main logic of privacy budget\n"
        
        col_inputdb = column(col, "inputdb")
        puts "col_inputdb= #{col_inputdb}\n"
        
        v1 = @inputdb[row*2][col_inputdb.to_sym]
        v2 = @inputdb[row*2+1][col_inputdb.to_sym]
        puts "v1= #{v1}\n"
        puts "v2= #{v2}\n"

        budget_cal(v1, fv, col_inputdb)
        budget_cal(v2, fv, col_inputdb)
         
      else
        puts "The attribute values you have chosen are same, hence cannot be disclosed\n"
        show_budget
      end
      
    else
      puts "You have entered c, entity resolution is done\n"
      show_budget 
      break
    end
  end 

end
