CREATE TABLE [InsightArchive].[HavenHolidays_CustomerMatches_20190508] (
    [FanID] INT NOT NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[HavenHolidays_CustomerMatches_20190508] TO [New_PIIRemoved]
    AS [dbo];

