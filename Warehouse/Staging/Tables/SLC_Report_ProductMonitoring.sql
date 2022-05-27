CREATE TABLE [Staging].[SLC_Report_ProductMonitoring] (
    [FanID]             INT          NOT NULL,
    [Day60AccountName]  VARCHAR (30) NULL,
    [Day120AccountName] VARCHAR (30) NULL,
    [JointAccount]      BIT          NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Staging].[SLC_Report_ProductMonitoring] TO [sfduser]
    AS [dbo];

