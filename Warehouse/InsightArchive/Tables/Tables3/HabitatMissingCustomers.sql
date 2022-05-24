CREATE TABLE [InsightArchive].[HabitatMissingCustomers] (
    [FanID] INT NOT NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[HabitatMissingCustomers] TO [New_PIIRemoved]
    AS [dbo];

