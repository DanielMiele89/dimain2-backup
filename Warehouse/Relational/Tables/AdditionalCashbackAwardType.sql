CREATE TABLE [Relational].[AdditionalCashbackAwardType] (
    [AdditionalCashbackAwardTypeID] INT           IDENTITY (1, 1) NOT NULL,
    [Title]                         VARCHAR (35)  NULL,
    [TransactionTypeID]             TINYINT       NULL,
    [ItemID]                        INT           NULL,
    [Description]                   VARCHAR (200) NULL,
    [PartnerCommissionRuleID]       INT           NULL,
    PRIMARY KEY CLUSTERED ([AdditionalCashbackAwardTypeID] ASC)
);

