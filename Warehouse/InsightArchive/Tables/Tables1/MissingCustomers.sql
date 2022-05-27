CREATE TABLE [InsightArchive].[MissingCustomers] (
    [FanID] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);




GO
DENY SELECT
    ON OBJECT::[InsightArchive].[MissingCustomers] TO [New_PIIRemoved]
    AS [dbo];

