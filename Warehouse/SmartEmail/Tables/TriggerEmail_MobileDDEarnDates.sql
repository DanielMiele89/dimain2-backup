CREATE TABLE [SmartEmail].[TriggerEmail_MobileDDEarnDates] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [BankAccountID]       INT          NULL,
    [IssuerBankAccountID] INT          NULL,
    [IssuerCustomerID]    INT          NULL,
    [SourceUID]           VARCHAR (50) NULL,
    [FanID]               INT          NULL,
    [EarnType]            VARCHAR (20) NULL,
    [FirstEarnDate]       DATE         NULL,
    [LastEarnDate]        DATE         NULL
);

