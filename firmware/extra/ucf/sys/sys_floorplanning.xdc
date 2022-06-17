create_pblock pblock_gold
add_cells_to_pblock [get_pblocks pblock_gold] -top

resize_pblock       [get_pblocks pblock_gold] -add  {CLOCKREGION_X0Y2:CLOCKREGION_X1Y3}
resize_pblock       [get_pblocks pblock_gold] -add  {MMCME2_ADV_X0Y2:MMCME2_ADV_X0Y2}
resize_pblock       [get_pblocks pblock_gold] -add  {PLLE2_ADV_X0Y2:PLLE2_ADV_X0Y3}
