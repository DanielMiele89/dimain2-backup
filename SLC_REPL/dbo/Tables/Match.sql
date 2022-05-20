CREATE TABLE [dbo].[Match] (
    [ID]                        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [AddedDate]                 DATETIME      NOT NULL,
    [VectorID]                  INT           NOT NULL,
    [VectorMajorID]             INT           NOT NULL,
    [VectorMinorID]             INT           NOT NULL,
    [PanID]                     INT           NULL,
    [MerchantID]                NVARCHAR (19) NOT NULL,
    [Amount]                    SMALLMONEY    NOT NULL,
    [TransactionDate]           DATETIME      NOT NULL,
    [Status]                    INT           NOT NULL,
    [RetailOutletID]            INT           NULL,
    [RewardStatus]              INT           NOT NULL,
    [Reversed]                  BIT           NOT NULL,
    [AffiliateCommissionShare]  FLOAT (53)    NULL,
    [AffiliateCommissionAmount] SMALLMONEY    NULL,
    [PartnerCommissionRate]     FLOAT (53)    NULL,
    [PartnerCommissionAmount]   SMALLMONEY    NULL,
    [VatRate]                   FLOAT (53)    NULL,
    [VatAmount]                 SMALLMONEY    NULL,
    [InvoiceID]                 INT           NULL,
    [PartnerCommissionRuleID]   INT           NULL,
    [CardInputMode]             VARCHAR (2)   NULL,
    [CardholderPresentData]     VARCHAR (2)   NULL,
    [IssuerBankAccountID]       INT           NULL,
    [DirectDebitOriginatorID]   INT           NULL,
    CONSTRAINT [PK_Match] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 70)
);


GO
CREATE NONCLUSTERED INDEX [ix_ID]
    ON [dbo].[Match]([ID] ASC)
    INCLUDE([VectorMajorID], [VectorMinorID]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_RetailOutletID_MerchantID]
    ON [dbo].[Match]([RetailOutletID] ASC, [MerchantID] ASC)
    INCLUDE([TransactionDate], [Amount], [PanID]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_RetailOutletID_PanID]
    ON [dbo].[Match]([RetailOutletID] ASC, [PanID] ASC)
    INCLUDE([TransactionDate]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Match] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Match] TO [PII_Removed]
    AS [dbo];

