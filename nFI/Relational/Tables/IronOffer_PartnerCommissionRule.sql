CREATE TABLE [Relational].[IronOffer_PartnerCommissionRule] (
    [ID]                         INT        NOT NULL,
    [PartnerID]                  SMALLINT   NULL,
    [TypeID]                     INT        NULL,
    [CommissionRate]             FLOAT (53) NULL,
    [Status]                     BIT        NULL,
    [Priority]                   INT        NULL,
    [DeletionDate]               DATETIME   NULL,
    [MaximumUsesPerFan]          INT        NULL,
    [NumberofPriorTransactions]  INT        NULL,
    [MinimumBasketSize]          SMALLMONEY NULL,
    [MaximumBasketSize]          SMALLMONEY NULL,
    [RequiredChannel]            SMALLINT   NULL,
    [RequiredClubID]             SMALLINT   NULL,
    [IronOfferID]                SMALLINT   NULL,
    [RequiredRetailOutletID]     INT        NULL,
    [RequiredCardholderPresence] INT        NULL,
    PRIMARY KEY NONCLUSTERED ([ID] ASC)
);


GO
CREATE CLUSTERED INDEX [IDX_IO]
    ON [Relational].[IronOffer_PartnerCommissionRule]([IronOfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_PI]
    ON [Relational].[IronOffer_PartnerCommissionRule]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_TID]
    ON [Relational].[IronOffer_PartnerCommissionRule]([TypeID] ASC);

