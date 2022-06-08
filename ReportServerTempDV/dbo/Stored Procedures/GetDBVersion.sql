
    CREATE PROCEDURE [dbo].[GetDBVersion]
    @DBVersion nvarchar(32) OUTPUT
    AS
    SET @DBVersion = (select top(1) [DbVersion]  from [dbo].[DBUpgradeHistory])
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetDBVersion] TO [RSExecRole]
    AS [dbo];

