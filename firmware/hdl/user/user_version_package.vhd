library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- encodes the version number. For consistent numbering, you must also modify the bitstream.xdc constraint file (under common)

package user_version_package is

    constant usr_ver_major : std_logic_vector(7 downto 0) := x"07";
    constant usr_ver_minor : std_logic_vector(7 downto 0) := x"00";
    constant usr_ver_patch : std_logic_vector(7 downto 0) := x"09";

end user_version_package;

package body user_version_package is
end user_version_package;
