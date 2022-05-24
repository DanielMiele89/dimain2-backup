CREATE TABLE [Relational].[IronOffer] (
    [IronOfferID]                 INT            NOT NULL,
    [IronOfferName]               NVARCHAR (200) NULL,
    [StartDate]                   DATETIME       NULL,
    [EndDate]                     DATETIME       NULL,
    [PartnerID]                   INT            NULL,
    [IsAboveTheLine]              BIT            NULL,
    [AutoAddToNewRegistrants]     BIT            NULL,
    [IsDefaultCollateral]         BIT            NULL,
    [IsSignedOff]                 BIT            NULL,
    [AreEligibleMembersCommitted] BIT            NULL,
    [AreControlMembersCommitted]  BIT            NULL,
    [IsTriggerOffer]              BIT            NULL,
    [Continuation]                BIT            NULL,
    [TopCashBackRate]             REAL           NULL,
    [AboveBase]                   BIT            NULL,
    [Clubs]                       NVARCHAR (7)   NULL,
    [CampaignType]                NVARCHAR (50)  NULL,
    [EarningCount]                NVARCHAR (10)  NULL,
    [EarningType]                 NVARCHAR (8)   NULL,
    [EarningLimit]                SMALLMONEY     NULL,
    PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Relational].[IronOffer]([PartnerID] ASC, [StartDate] ASC)
    INCLUDE([IsTriggerOffer], [AboveBase], [IronOfferName], [EndDate]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

