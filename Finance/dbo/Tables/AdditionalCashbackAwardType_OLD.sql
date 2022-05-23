CREATE TABLE [dbo].[AdditionalCashbackAwardType_OLD] (
    [AdditionalCashbackAwardTypeID] SMALLINT      NOT NULL,
    [Title]                         VARCHAR (35)  NOT NULL,
    [TransactionTypeID]             SMALLINT      NOT NULL,
    [ItemID]                        INT           NULL,
    [TypeDescription]               VARCHAR (200) NULL,
    [PartnerCommissionRuleID]       INT           NULL,
    [CreatedDateTime]               DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]               DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_AdditionalCashbackAwardType_OLD] PRIMARY KEY CLUSTERED ([AdditionalCashbackAwardTypeID] ASC),
    CONSTRAINT [FK_AdditionalCashbackAwardType_TransactionTypeID_OLD] FOREIGN KEY ([TransactionTypeID]) REFERENCES [dbo].[TransactionType_OLD] ([TransactionTypeID])
);

