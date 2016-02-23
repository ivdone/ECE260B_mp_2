proc PtSwapCell {cell_instance cell_master} {
    set swap_status [swap_cell $cell_instance $cell_master]
    return $swap_status
}

proc PtCellLeak { cell_name } {
    set cell [get_cell $cell_name]
    set power [get_attri $cell leakage_power]
    return $power
}

proc PtLeakPower {} {
    set power [get_attri [current_design] leakage_power]
    return $power
}

proc PtGetCapVio { } {


    global sh_product_version
    global sh_dev_null
    global pt_tmp_dir
    global report_default_significant_digits
    global synopsys_program_name

    redirect $pt_tmp_dir/tmp.[pid] {report_constraint -all_violators -nosplit -significant_digits 5 -max_capacitance}

    set REPORT_FILE [open $pt_tmp_dir/tmp.[pid] r]
    set drc_list ""
    set cost 0.0
    set count 0
    set max_cost 0

    while {[gets $REPORT_FILE line] >= 0} {
      switch -regexp $line {
        {^.* +([-\.0-9]+) +\(VIOLATED} {
          regexp {^.* +([-\.0-9]+) +\(VIOLATED} $line full slack
          set cost [expr $cost + $slack]
          incr count
          if { $max_cost > $slack } {
              set max_cost $slack
          }
          continue
        }
      }
    }

    close $REPORT_FILE
    catch {file delete -force $pt_tmp_dir/tmp.[pid]}
    if {$cost == 0} {
        return "Sum/Max/Number of max capacitance violations: 0 / 0 / 0"
    } else {
        return "Sum/Max/Number of max capacitance violations: [expr -$cost] / [expr -$max_cost] / $count"
    }
}


proc PtGetTranVio { } {
    global sh_product_version
    global sh_dev_null
    global pt_tmp_dir
    global report_default_significant_digits
    global synopsys_program_name

    redirect $pt_tmp_dir/tmp.[pid] {report_constraint -all_violators -nosplit -significant_digits 5 -max_transition}

    set REPORT_FILE [open $pt_tmp_dir/tmp.[pid] r]
    set drc_list ""
    set cost 0.0
    set count 0
    set max_cost 0

    while {[gets $REPORT_FILE line] >= 0} {
      switch -regexp $line {
        {^.* +([-\.0-9]+) +\(VIOLATED} {
          regexp {^.* +([-\.0-9]+) +\(VIOLATED} $line full slack
          set cost [expr $cost + $slack]
          incr count
          if { $max_cost > $slack } {
              set max_cost $slack
          }
          continue
        }
      }
    }

    close $REPORT_FILE
    catch {file delete -force $pt_tmp_dir/tmp.[pid]}
    if {$cost == 0} {
        return "Sum/Max/Number of max transition violations: 0 / 0 / 0"
    } else {
        return "Sum/Max/Number of max transition violations: [expr -$cost] / [expr -$max_cost] / $count"
    }
}

proc PtGetPinMaxTran { pin_name } {
    if { [get_ports -quiet $pin_name] == "" } {
        set pin [get_pin $pin_name]
    } else {
        set pin [get_ports $pin_name]
    }
    set tran [get_attribute -quiet $pin max_transition]

    return $tran
}

proc PtGetPinMaxCap { pin_name } {
    if { [get_ports -quiet $pin_name] == "" } {
        set pin [get_pin $pin_name]
    } else {
        set pin [get_ports $pin_name]
    }
    set cap [get_attribute -quiet $pin max_capacitance]

    return $cap
}



proc PtGetPinTran { pin_name } {
    if { [get_ports -quiet $pin_name] == "" } {
        set pin [get_pin $pin_name]
    } else {
        set pin [get_ports $pin_name]
    }
    set riseTrans [get_attribute -quiet $pin actual_rise_transition_max]
    set fallTrans [get_attribute -quiet $pin actual_fall_transition_max]

    set tran [expr max($riseTrans,$fallTrans)]

    return $tran
}



proc PtGetPinLoadCap { pin_name } {
    if { [get_ports -quiet $pin_name] == "" } {
      set pin [get_pin $pin_name]
      set pin_direction [get_attribute -class pin $pin direction]
      if { $pin_direction == "in"} {
        return "0.0 0.0"
      }
    } else {
      set pin [get_ports $pin_name]
      set pin_direction [get_attribute -class port $pin direction]
      if { $pin_direction == "out"} {
        return "0.0 0.0"
      }
    }

    set net [get_net -of_object $pin]
    set cap [get_attribute -quiet $net total_capacitance_max]
    return $cap
}

proc PtCellSlack { cell_name } {
	  set worst_slack 10000
    foreach_in_collection pin [get_pins -of $cell_name -filter "direction==out"] {
        set rise_slack [get_attribute $pin max_rise_slack] 
        set fall_slack [get_attribute $pin max_fall_slack] 
        if {$rise_slack < $worst_slack} {
            set worst_slack $rise_slack
        }
        if {$fall_slack < $worst_slack} {
            set worst_slack $fall_slack
        }
    }
    return $worst_slack
}

# An example to sort cells based on their slacks
proc sortCells { cell_collection } {
    define_user_attribute -type float -class cell CellSlack
    foreach_in_collection cell $cell_collection {
      set_user_attribute $cell CellSlack [PtCellSlack $cell]
    }
    set new_collection [sort_collection -descending $cell_collection {CellSlack}]
    return $new_collection
}

proc RecoverTiming { cell_collection } {
    
    foreach_in_collection cell $cell_collection {
      set cellName [get_attri $cell base_name]
      foreach vt {s m f} {
        foreach size {02 03 04 06 08 10 20 40 80} {
          puts "Attempting size $size and Vt $vt for cell $cellName..."
          set libcellName [get_attri $cell ref_name]
          set current_WNS [PtWorstSlack clk]
          
          set newlibcellName [string replace $libcellName 5 6 $size]
          set newlibcellName [string replace $newlibcellName 4 4 $vt]
          size_cell $cellName $newlibcellName
          set new_WNS [PtWorstSlack clk]
          
          if {$new_WNS >= 0} {
            puts "No negative slack!"
            return 1
          }
          
          if {$new_WNS <= $current_WNS} {
            size_cell $cellName $libcellName
            puts "Reverting..."
            break
          }
          
        }
      }
    }
    return 0
}

proc PtCellDelay { cell_name } {
    set pin [get_pins -of $cell_name]
    set max_worst 0 
    set out_arrival 0
    set max_delay 0
    set cell_delay 0
    foreach_in_collection each_pin $pin {
        set pinDirection [get_attri $each_pin direction]
        if {$pinDirection == "out" } {
            set rise_arrival [get_attribute $each_pin max_rise_arrival] 
            set fall_arrival [get_attribute $each_pin max_fall_arrival] 
            if {$rise_arrival > $fall_arrival} {
                set worst_arrival $rise_arrival
            } else {
                set worst_arrival $fall_arrival
            }
            if {$worst_arrival > $out_arrival} {
                set out_arrival $worst_arrival
            }
        }
    }
    #puts "out $out_arrival"
    foreach_in_collection each_pin $pin {
        set pinDirection [get_attri $each_pin direction]
        if {$pinDirection == "in" } {
            set rise_arrival [get_attribute $each_pin max_rise_arrival] 
            if {$rise_arrival == ""} {
                continue 
            }
            set fall_arrival [get_attribute $each_pin max_fall_arrival] 
            if {$fall_arrival == ""} {
                continue 
            }
            if {$rise_arrival > $fall_arrival} {
                set worst_arrival $rise_arrival
            } else {
                set worst_arrival $fall_arrival
            }
            set max_delay [expr $out_arrival - $worst_arrival] 
            if {$max_delay > $cell_delay} {
                set cell_delay $max_delay
            }
        }
    }
    return $cell_delay
}

proc PtWorstSlack { clk_name } {
    set path [get_timing_path -nworst 1 -group $clk_name]
    set path_slack [get_attribute $path slack]
    return $path_slack
}

proc PtGetLibCell { CellName } {  
    set Cell [get_cell $CellName]
    set LibCell [get_lib_cells -of_objects $Cell]
    set LibCellName [get_attri $LibCell base_name]
    return $LibCellName
}

proc PtSizeCell {Cell cell_master} {
  set size_status [size_cell $Cell $cell_master]
  return $size_status
}

proc PtWriteChange { FileName } {
  set cmd "write_changes -format ptsh -out $FileName"
  set status [eval $cmd]
  catch {exec touch $FileName}
  catch {exec echo "current_instance" >> $FileName}
  return $status
}


proc getNextSizeUp { cell } {
    if { [regexp {[a-z][a-z][0-9][0-9][smf]01} $cell]} {
        set newSize [string replace $cell 5 6 02]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]02} $cell]} {
        set newSize [string replace $cell 5 6 03]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]03} $cell]} {
        set newSize [string replace $cell 5 6 04]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]04} $cell]} {
        set newSize [string replace $cell 5 6 06]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]06} $cell]} {
        set newSize [string replace $cell 5 6 08]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]08} $cell]} {
        set newSize [string replace $cell 5 6 10]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]10} $cell]} {
        set newSize [string replace $cell 5 6 20]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]20} $cell]} {
        set newSize [string replace $cell 5 6 40]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]40} $cell]} {
        set newSize [string replace $cell 5 6 80]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]80} $cell]} {
        set newSize [string replace $cell 5 6 80]
        return $newSize
    }
}

proc getNextSizeDown { cell } {
    if { [regexp {[a-z][a-z][0-9][0-9][smf]80} $cell]} {
        set newSize [string replace $cell 5 6 40]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]40} $cell]} {
        set newSize [string replace $cell 5 6 20]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]20} $cell]} {
        set newSize [string replace $cell 5 6 10]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]10} $cell]} {
        set newSize [string replace $cell 5 6 08]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]08} $cell]} {
        set newSize [string replace $cell 5 6 06]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]06} $cell]} {
        set newSize [string replace $cell 5 6 04]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]04} $cell]} {
        set newSize [string replace $cell 5 6 03]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]03} $cell]} {
        set newSize [string replace $cell 5 6 02]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]02} $cell]} {
        set newSize [string replace $cell 5 6 01]
        return $newSize
    }

    if { [regexp {[a-z][a-z][0-9][0-9][smf]01} $cell]} {
	return "skip"
    }
}

proc getNextVtDown { libcellName } {
	if { [regexp {[a-z][a-z][0-9][0-9]f[0-9][0-9]} $libcellName] } { 
	        set newlibcellName [string replace $libcellName 4 4 m]
		return $newlibcellName
	}
	
	if { [regexp {[a-z][a-z][0-9][0-9]m[0-9][0-9]} $libcellName] } { 
        	set newlibcellName [string replace $libcellName 4 4 s]
		return $newlibcellName
	}
	
	if { [regexp {[a-z][a-z][0-9][0-9]s[0-9][0-9]} $libcellName] } { 
		return "skip"
	}

}

proc getNextVtUp { libcellName } {
	if { [regexp {[a-z][a-z][0-9][0-9]m[0-9][0-9]} $libcellName] } { 
        set newlibcellName [string replace $libcellName 4 4 f]
		return $newlibcellName
	}
	
	if { [regexp {[a-z][a-z][0-9][0-9]s[0-9][0-9]} $libcellName] } { 
        set newlibcellName [string replace $libcellName 4 4 m]
		return $newlibcellName
	}
	
	if { [regexp {[a-z][a-z][0-9][0-9]f[0-9][0-9]} $libcellName] } { 
        set newlibcellName $libcellName
		return $newlibcellName
	}

}

proc PtCellFanout { cell_name } {
    set outPin [get_pins -of $cell_name -filter "direction==out"]
    set net [all_connected $outPin]
    if {[sizeof $net] == 0} {
        return 0.0
    }
    return [expr [sizeof [all_connected $net -leaf]]-1]
}

proc checkLegit { cell_name } {
    set newWNS [ PtWorstSlack clk ]

    if { $newWNS < 0.0 } {
        return 0
    }

    foreach_in_collection outPin [get_pins -of $cell_name -filter "direction==out"] {
        set maxTran [PtGetPinMaxTran $outPin]
        set Tran [PtGetPinTran $outPin]
        set maxCap [PtGetPinMaxCap $outPin]
        set Cap [PtGetPinLoadCap $outPin]

        if { $maxTran < $Tran } {
            return 0
        }
        if { $maxCap < $Cap} {
            return 0
        }
    }
    foreach_in_collection inPin [get_pins -of $cell_name -filter "direction==in"] {
        set maxTran [PtGetPinMaxTran $inPin]
        set Tran [PtGetPinTran $inPin]
        if { $maxTran < $Tran } {
            return 0
        }
    }
    return 1
}

proc setSensitivity {cell} {
    
    define_user_attribute -type float -class cell Sensitivity
    define_user_attribute -type string -class cell newlibcellName
 
    #get cell slack
    set cellName [get_attri $cell base_name]
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set cellSlack [PtCellSlack $cellName]
    
    if {$cellSlack <= 0} {
      set_user_attribute $cell Sensitivity 0.0
      set_user_attribute $cell newlibcellName $libcellName
      return 0
    }

    #get number of path
    set pin [get_pins -of $cellName]
    set path [get_timing_path -through $pin]
    set pathNum [sizeof $path]
    if {$path <= 0} {
      set_user_attribute $cell Sensitivity 0.0
      set_user_attribute $cell newlibcellName $libcellName
      return 0
    }
    
    #get leakage power based on different modifications
    set leakPre [PtLeakPower]

    if {$libcellName == "ms00f80"} {
      set_user_attribute $cell Sensitivity 0.0
      set_user_attribute $cell newlibcellName $libcellName
      return 0
    }
    set cellNameDown1 [getNextSizeDown $libcellName]
    set cellNameDown2 [getNextSizeDown $cellNameDown1]
    set cellNameUp1 [getNextVtUp $libcellName]
    set cellNameUp2 [getNextVtUp $cellNameUp1]
    set cellNameDown1Up1 [getNextVtUp $cellNameDown1]
    set cellNameDown1Up2 [getNextVtUp $cellNameDown1Up1]
    set cellNameDown2Up1 [getNextSizeDown $cellNameDown1Up1]
    set cellNameDown2Up2 [getNextVtUp $cellNameDown2Up1]


    size_cell $cellName $cellNameDown1
    set leakAftD1U0 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD1U0 [expr $leakPre - $leakAftD1U0]
    set senD1U0 [expr $deltaLeakD1U0 * $cellSlack / $pathNum]
    
    size_cell $cellName $cellNameDown2
    set leakAftD2U0 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD2U0 [expr $leakPre - $leakAftD2U0]
    set senD2U0 [expr $deltaLeakD2U0 * $cellSlack / $pathNum]

    size_cell $cellName $cellNameUp1
    set leakAftD0U1 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD0U1 [expr $leakPre - $leakAftD0U1]
    set senD0U1 [expr $deltaLeakD0U1 * $cellSlack / $pathNum]

    size_cell $cellName $cellNameUp2
    set leakAftD0U2 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD0U2 [expr $leakPre - $leakAftD0U2]
    set senD0U2 [expr $deltaLeakD0U2 * $cellSlack / $pathNum]

    size_cell $cellName $cellNameDown1Up1
    set leakAftD1U1 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD1U1 [expr $leakPre - $leakAftD1U1]
    set senD1U1 [expr $deltaLeakD1U1 * $cellSlack / $pathNum]

    size_cell $cellName $cellNameDown1Up2
    set leakAftD1U2 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD1U2 [expr $leakPre - $leakAftD1U2]
    set senD1U2 [expr $deltaLeakD1U2 * $cellSlack / $pathNum]

    size_cell $cellName $cellNameDown2Up1
    set leakAftD2U1 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD2U1 [expr $leakPre - $leakAftD2U1]
    set senD2U1 [expr $deltaLeakD2U1 * $cellSlack / $pathNum]

    size_cell $cellName $cellNameDown2Up2
    set leakAftD2U2 [PtLeakPower]
    size_cell $cellName $libcellName
    set deltaLeakD2U2 [expr $leakPre - $leakAftD2U2]
    set senD2U2 [expr $deltaLeakD2U2 * $cellSlack / $pathNum]

    set finalName $cellNameDown1
    set finalSen $senD1U0
    if { $finalSen < $senD2U0 } { 
	set finalName $cellNameDown2
	set finalSen $senD2U0
    } else { if { $finalSen < $senD0U1 } { 
	set finalName $cellNameUp1
	set finalSen $senD0U1
    } else { if { $finalSen < $senD0U2 } { 
	set finalName $cellNameUp2
	set finalSen $senD0U2
    } else { if { $finalSen < $senD1U1 } { 
	set finalName $cellNameDown1Up1
	set finalSen $senD1U1
    } else { if { $finalSen < $senD2U1 } { 
	set finalName $cellNameDown2Up1
	set finalSen $senD2U1
    } else { if { $finalSen < $senD1U2 } { 
	set finalName $cellNameDown1Up2
	set finalSen $senD1U2
    } else { if { $finalSen < $senD2U2 } { 
	set finalName $cellNameDown2Up2
	set finalSen $senD2U2
   } } } } } } }

   set_user_attribute $cell Sensitivity $finalSen
   set_user_attribute $cell newlibcellName $finalName

    return 1
    #set delayPre [PtCellDelay $cell_name]
}

# An example to sort cells based on their sensitivity
proc sortSensitivity { cell_collection } {
    foreach_in_collection cell $cell_collection {
      set flag [setSensitivity $cell] 
    }
    set new_collection [sort_collection -descending $cell_collection {Sensitivity}]
    return $new_collection
}
