reagentc /disable

@"
sel disk 0
list part
sel part 4
delete part override
sel part 3
extend
"@ | diskpart
