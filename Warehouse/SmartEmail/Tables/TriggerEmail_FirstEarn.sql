CREATE TABLE [SmartEmail].[TriggerEmail_FirstEarn] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [FanID]         INT          NULL,
    [AccountName]   VARCHAR (50) NULL,
    [FirstEarnType] VARCHAR (20) NULL,
    [FirstEarnDate] DATE         NULL
);

