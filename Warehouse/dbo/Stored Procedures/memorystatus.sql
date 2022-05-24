CREATE proc memorystatus
with execute as owner
as
execute as login='nirupam'
dbcc memorystatus
revert