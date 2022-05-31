CREATE TABLE [Prod].[Match] (
    [ID]                             INT           NOT NULL,
    [AddedDate]                      DATETIME      NOT NULL,
    [VectorID]                       INT           NOT NULL,
    [VectorMajorID]                  INT           NOT NULL,
    [VectorMinorID]                  INT           NOT NULL,
    [PanID]                          INT           NULL,
    [MerchantID]                     NVARCHAR (19) NOT NULL,
    [Amount]                         SMALLMONEY    NOT NULL,
    [TransactionDate]                DATETIME      NOT NULL,
    [Status]                         INT           NOT NULL,
    [RetailOutletID]                 INT           NULL,
    [RewardStatus]                   INT           NOT NULL,
    [Reversed]                       BIT           NOT NULL,
    [AffiliateCommissionShare]       FLOAT (53)    NULL,
    [AffiliateCommissionAmount]      SMALLMONEY    NULL,
    [PartnerCommissionRate]          FLOAT (53)    NULL,
    [PartnerCommissionAmount]        SMALLMONEY    NULL,
    [VatRate]                        FLOAT (53)    NULL,
    [VatAmount]                      SMALLMONEY    NULL,
    [InsertedManually]               BIT           NULL,
    [InvoiceID]                      INT           NULL,
    [ReportedToAffiliate]            BIT           NULL,
    [ReportedToAffiliateDate]        DATETIME      NULL,
    [BillerID]                       INT           NULL,
    [BillerCollectionDate]           DATETIME      NULL,
    [BillerPaymentID]                INT           NULL,
    [BillerPaymentDate]              DATETIME      NULL,
    [PartnerCommissionRuleID]        INT           NULL,
    [AffiliateCommissionShareRuleID] INT           NULL,
    CONSTRAINT [PK_Match] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_Match_TransactionDate]
    ON [Prod].[Match]([TransactionDate] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Archive_Light_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_Match_VectorStatusInclTranDate]
    ON [Prod].[Match]([VectorID] ASC, [VectorMajorID] ASC, [VectorMinorID] ASC, [Status] ASC)
    INCLUDE([TransactionDate]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Archive_Light_Indexes];

