set design _DESIGN_

loadConfig ./temp.conf 0
commitConfig

set home "/home/linux/ieng6/ee260b/public/data/libraries"
readCapTable -worst "$home/techfiles/cln65g+_1p08m+alrdl_top2_cworst.captable" -best "$home/techfiles/cln65g+_1p08m+alrdl_top2_cworst.captable"

# set operating temperature

setExtractRCMode -coupled true -engine postRoute
defineRCCorner -late {worst} 125 -early {best} -40

defIn ${design}.def

report_timing

set swapList ""
set flag 0
set inFile [open ${design}_sizing.rpt]
while {[gets $inFile line]>=0} {

    if {[regexp {===} $line] && $flag == 1} {
        incr flag
    }

    if {$flag == 1} {
        set instName [lindex $line 2]
        set newCellName [lindex $line end]
        set inst [get_cells -quiet $instName]
        if {[sizeof_collection $inst] == 0} {
            continue    
        }
        set orgCellName [get_property $inst ref_name]
        if {$orgCellName == $newCellName} {
            continue
        }
        set orgCell($instName) $orgCellName
        set newCell($instName) $newCellName
        set visited($instName) 0
        lappend swapList $instName
    }

    if {[regexp {===} $line] && $flag == 0} {
        incr flag
    }
}   
close $inFile

setEcoMode -batchMode true
setEcoMode -refinePlace false
foreach instName $swapList {
    set orgSize "[string index $orgCell($instName) end-1][string index $orgCell($instName) end]"
    set newSize "[string index $newCell($instName) end-1][string index $newCell($instName) end]"
    if {$orgSize == $newSize} {
        ecoChangeCell -inst $instName -cell $newCell($instName)
        set visited($instName) 1
    }
}
setEcoMode -batchMode false

setEcoMode -batchMode true
setEcoMode -refinePlace true
foreach instName $swapList {
    if {$visited($instName) == 0} {
        ecoChangeCell -inst $instName -cell $newCell($instName)
    }
}
setEcoMode -batchMode false

report_timing

saveNetlist ${design}_eco.v

exec echo "clk" > excNet.rpt
rcOut -excNetFile excNet.rpt -spef ${design}_eco.spef
defOut -routing ${design}_eco.def

exit
