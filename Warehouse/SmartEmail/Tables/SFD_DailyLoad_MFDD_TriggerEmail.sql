CREATE TABLE [SmartEmail].[SFD_DailyLoad_MFDD_TriggerEmail] (
    [ID]                INT  IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT  NULL,
    [IronOfferID]       INT  NULL,
    [OIN]               INT  NULL,
    [BankAccountID]     INT  NULL,
    [FanID]             INT  NULL,
    [TransactionNumber] INT  NULL,
    [EmailDate]         DATE NULL
);

