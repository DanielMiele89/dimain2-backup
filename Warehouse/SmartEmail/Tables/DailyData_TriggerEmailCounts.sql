CREATE TABLE [SmartEmail].[DailyData_TriggerEmailCounts] (
    [SendDate]         DATE          NULL,
    [TriggerEmail]     VARCHAR (100) NULL,
    [Brand]            VARCHAR (3)   NULL,
    [Loyalty]          VARCHAR (5)   NULL,
    [CustomersEmailed] INT           NULL
);


GO
CREATE CLUSTERED INDEX [IX_SendDateEmailBank]
    ON [SmartEmail].[DailyData_TriggerEmailCounts]([SendDate] ASC, [TriggerEmail] ASC, [Brand] ASC, [Loyalty] ASC);

