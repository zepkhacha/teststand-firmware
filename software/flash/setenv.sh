export FLASH_TOOL_ROOT=$( readlink -f $(dirname $BASH_SOURCE)/ )
export LD_LIBRARY_PATH=$FLASH_TOOL_ROOT/lib:${LD_LIBRARY_PATH}
export PATH=${FLASH_TOOL_ROOT}/bin:${PATH}
