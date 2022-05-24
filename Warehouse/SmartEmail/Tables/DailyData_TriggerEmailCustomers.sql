CREATE TABLE [SmartEmail].[DailyData_TriggerEmailCustomers] (
    [SendDate]                          DATE          NULL,
    [TriggerEmail]                      VARCHAR (100) NULL,
    [Brand]                             VARCHAR (3)   NULL,
    [Loyalty]                           VARCHAR (5)   NULL,
    [FanID]                             INT           NOT NULL,
    [InCountsTable]                     BIT           NULL,
    [WelcomeEmailCode]                  VARCHAR (100) NULL,
    [Homemover]                         BIT           NULL,
    [FirstEarnDate]                     DATE          NULL,
    [FirstEarnType]                     VARCHAR (100) NULL,
    [Day60AccountName]                  VARCHAR (40)  NULL,
    [Day120AccountName]                 VARCHAR (40)  NULL,
    [LoyaltyAccount]                    BIT           NULL,
    [DirectDebitEarn_PartnerID]         INT           NULL,
    [DirectDebitEarn_TransactionNumber] INT           NULL,
    [MobileDormant]                     INT           NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_SendDateEmailBank_Fan]
    ON [SmartEmail].[DailyData_TriggerEmailCustomers]([SendDate] ASC, [TriggerEmail] ASC, [Brand] ASC, [Loyalty] ASC);

