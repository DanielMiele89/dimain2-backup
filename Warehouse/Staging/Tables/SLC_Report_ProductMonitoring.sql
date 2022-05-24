CREATE TABLE [Staging].[SLC_Report_ProductMonitoring] (
    [FanID]             INT          NOT NULL,
    [Day60AccountName]  VARCHAR (30) NULL,
    [Day120AccountName] VARCHAR (30) NULL,
    [JointAccount]      BIT          NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

