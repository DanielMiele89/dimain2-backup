CREATE proc memorystatus
with execute as owner
as
execute as login='nirupam'
dbcc memorystatus
revert
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[memorystatus] TO [Ed]
    AS [dbo];

