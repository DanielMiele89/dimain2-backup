CREATE TABLE [Email].[TriggerEmailCustomers] (
    [ID]                      BIGINT        IDENTITY (1, 1) NOT NULL,
    [FanID]                   INT           NULL,
    [TriggerEmailTypeID]      INT           NULL,
    [EmailSendDate]           DATE          NULL,
    [Birthday_Code]           VARCHAR (255) NULL,
    [Birthday_CodeExpiryDate] VARCHAR (255) NULL,
    [FirstEarn_RetailerName]  VARCHAR (255) NULL,
    [FirstEarn_Date]          VARCHAR (255) NULL,
    [FirstEarn_Amount]        VARCHAR (255) NULL,
    [FirstEarn_Type]          VARCHAR (255) NULL,
    [Reached5GBP_Date]        DATE          NULL,
    [EarnConfirmation_Date]   DATE          NULL,
    [RedeemReminder_Amount]   NVARCHAR (24) NULL,
    [RedeemReminder_Day]      INT           NULL
);

