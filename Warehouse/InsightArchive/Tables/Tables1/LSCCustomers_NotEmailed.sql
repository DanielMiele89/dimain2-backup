CREATE TABLE [InsightArchive].[LSCCustomers_NotEmailed] (
    [FanID] INT NOT NULL
);




GO
DENY SELECT
    ON OBJECT::[InsightArchive].[LSCCustomers_NotEmailed] TO [New_PIIRemoved]
    AS [dbo];

