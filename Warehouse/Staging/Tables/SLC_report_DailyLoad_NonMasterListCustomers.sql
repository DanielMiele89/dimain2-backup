CREATE TABLE [Staging].[SLC_report_DailyLoad_NonMasterListCustomers] (
    [FanID] INT NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[Staging].[SLC_report_DailyLoad_NonMasterListCustomers] TO [sfduser]
    AS [dbo];

