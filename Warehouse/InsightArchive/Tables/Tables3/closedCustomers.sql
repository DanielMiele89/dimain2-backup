CREATE TABLE [InsightArchive].[closedCustomers] (
    [FanID] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[closedCustomers] TO [New_PIIRemoved]
    AS [dbo];

