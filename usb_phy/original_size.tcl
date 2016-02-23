set design [get_attri [current_design] full_name]
set outFp [open ${design}_sizing.rpt w]

set initialWNS  [ PtWorstSlack clk ]
set initialLeak [ PtLeakPower ]
set capVio [ PtGetCapVio ]
set tranVio [ PtGetTranVio ]
puts $outFp "Initial slack:\t${initialWNS} ps"
puts $outFp "Initial leakage:\t${initialLeak} W"
puts $outFp "Final $capVio"
puts $outFp "Final $tranVio"
puts $outFp "======================================" 

set cellList [get_cell *]
set VtswapCnt 0
set SizeswapCnt 0

set newCellList [sortCells $cellList]

foreach_in_collection cell $newCellList {
    set cellName [get_attri $cell base_name]
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    if {$libcellName == "ms00f80"} {
        continue
    }
    #Vt cell swap example (convert all fast cells (i.e. LVT) to medium cells (i.e. NVT)...
    if { [regexp {[a-z][a-z][0-9][0-9]f[0-9][0-9]} $libcellName] } { 
        set newlibcellName [string replace $libcellName 4 4 m] 
        size_cell $cellName $newlibcellName
        
        set checkRs [ checkLegit $cellName ]
        if { $checkRs == 0 } {
            size_cell $cellName $libcellName
        } else {
            incr VtswapCnt
            puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
        }
    }
    #Vt cell swap example (convert all medium cells (i.e. NVT) to slow cells (i.e. HVT)...

    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]

    if { [regexp {[a-z][a-z][0-9][0-9]m[0-9][0-9]} $libcellName] } { 
        set newlibcellName [string replace $libcellName 4 4 s] 
        size_cell $cellName $newlibcellName
        
        set checkRs [ checkLegit $cellName ]
        if { $checkRs == 0 } {
            size_cell $cellName $libcellName
        } else {
            incr VtswapCnt
            puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
        }
    }
    #       ----------------------------------------------------------------------
    #cell size swap 1
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
        
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #cell size swap 2
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
        
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #cell size swap 3
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
        
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #cell size swap 4
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
        
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #cell size swap 5
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
        
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #cell size swap 6
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
        
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #cell size swap 7
    set libcell [get_lib_cells -of_objects $cellName]
    set libcellName [get_attri $libcell base_name]
    set newlibcellName [getNextSizeDown $libcellName]
    size_cell $cellName $newlibcellName
    
    set checkRs [ checkLegit $cellName ]
    if { $checkRs == 0 } {
        size_cell $cellName $libcellName
    } else {
        incr SizeswapCnt
        puts $outFp "- cell ${cellName} is swapped to $newlibcellName"
    }
    #       ----------------------------------------------------------------------    
    
}

set finalWNS  [ PtWorstSlack clk ]
set finalLeak [ PtLeakPower ]
set capVio [ PtGetCapVio ]
set tranVio [ PtGetTranVio ]
set improvment  [format "%.3f" [expr ( $initialLeak - $finalLeak ) / $initialLeak * 100.0]]
puts $outFp "======================================" 
puts $outFp "Final slack:\t${finalWNS} ps"
puts $outFp "Final leakage:\t${finalLeak} W"
puts $outFp "Final $capVio"
puts $outFp "Final $tranVio"
puts $outFp "#Vt cell swaps:\t${VtswapCnt}"
puts $outFp "#Cell size swaps:\t${SizeswapCnt}"
puts $outFp "Leakage improvment\t${improvment} %"

close $outFp    


