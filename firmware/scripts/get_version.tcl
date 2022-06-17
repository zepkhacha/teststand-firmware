global version

catch {set fptr [open [file dirname [info script]]/../hdl/user/user_version_package.vhd r]};
set contents [read -nonewline $fptr]; # Read the file contents
close $fptr;                          # Close the file since it has been read now
set splitCont [split $contents "\n"]; # Split the files contents on new line
foreach ele $splitCont {
  [regexp {usr_ver_major.*x"(..)"} $ele -> major_rev]
  [regexp {usr_ver_minor.*x"(..)"} $ele -> minor_rev]
  [regexp {usr_ver_patch.*x"(..)"} $ele -> patch_rev]
}

set version "0x$major_rev$minor_rev$patch_rev"
