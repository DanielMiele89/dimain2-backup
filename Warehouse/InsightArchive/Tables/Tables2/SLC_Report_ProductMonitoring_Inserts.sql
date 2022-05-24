CREATE TABLE [InsightArchive].[SLC_Report_ProductMonitoring_Inserts] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [FanID]             INT          NOT NULL,
    [Day60AccountName]  VARCHAR (30) NULL,
    [Day120AccountName] VARCHAR (30) NULL,
    [JointAccount]      BIT          NULL,
    [InsertedBy]        TINYINT      NOT NULL,
    [InsertedDate]      DATETIME     DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

