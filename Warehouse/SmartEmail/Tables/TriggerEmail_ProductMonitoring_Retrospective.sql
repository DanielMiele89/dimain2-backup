CREATE TABLE [SmartEmail].[TriggerEmail_ProductMonitoring_Retrospective] (
    [FanID]             INT          NOT NULL,
    [Day60AccountName]  VARCHAR (30) NULL,
    [Day120AccountName] VARCHAR (30) NULL,
    [JointAccount]      BIT          NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

