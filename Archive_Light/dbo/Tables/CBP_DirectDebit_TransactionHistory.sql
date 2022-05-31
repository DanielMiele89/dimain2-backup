CREATE TABLE [dbo].[CBP_DirectDebit_TransactionHistory] (
    [FileID]                    INT           NOT NULL,
    [RowNum]                    INT           NOT NULL,
    [BankID]                    VARCHAR (4)   NOT NULL,
    [SortCode]                  VARCHAR (6)   NOT NULL,
    [MaskedAccountNumber]       VARCHAR (8)   NOT NULL,
    [Amount]                    MONEY         NOT NULL,
    [OIN]                       INT           NOT NULL,
    [Date]                      DATE          NOT NULL,
    [Narrative]                 NVARCHAR (18) NOT NULL,
    [IssuerID]                  INT           NULL,
    [ClubID]                    INT           NULL,
    [DirectDebitOriginatorID]   INT           NULL,
    [DirectDebitCategory1ID]    INT           NULL,
    [Rate]                      FLOAT (53)    NULL,
    [TransItemID]               INT           NULL,
    [BankAccountID]             INT           NULL,
    [BankAccountTypeHistoryID]  INT           NULL,
    [BankAccountType]           VARCHAR (3)   NULL,
    [IssuerBankAccountID]       INT           NULL,
    [IssuerCustomerID]          INT           NULL,
    [SourceUID]                 VARCHAR (20)  NULL,
    [FanID]                     INT           NULL,
    [FanActivationDate]         DATE          NULL,
    [DDCashbackNomineeID]       INT           NULL,
    [IsDDCashbackNominee]       BIT           NULL,
    [IssuerCustomerAttributeID] INT           NULL,
    [CustomerSegment]           VARCHAR (8)   NULL,
    [MatchStatus]               TINYINT       NULL,
    [RewardStatus]              TINYINT       NULL,
    [LoyaltyFlag]               VARCHAR (3)   NULL,
    CONSTRAINT [PK_CBP_DirectDebit_TransactionHistory] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [dbo].[CBP_DirectDebit_TransactionHistory]([OIN] ASC, [Date] ASC)
    INCLUDE([Amount], [Narrative], [ClubID], [SourceUID]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Archive_Light_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [dbo].[CBP_DirectDebit_TransactionHistory]([Date] ASC, [Narrative] ASC)
    INCLUDE([Amount], [OIN], [FanID]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Archive_Light_Indexes];


GO
GRANT INSERT
    ON OBJECT::[dbo].[CBP_DirectDebit_TransactionHistory] TO [gas]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[CBP_DirectDebit_TransactionHistory] TO [gas]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[CBP_DirectDebit_TransactionHistory] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[CBP_DirectDebit_TransactionHistory] TO [shaun]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[CBP_DirectDebit_TransactionHistory] TO [Matt]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[CBP_DirectDebit_TransactionHistory] TO [Insight]
    AS [dbo];

