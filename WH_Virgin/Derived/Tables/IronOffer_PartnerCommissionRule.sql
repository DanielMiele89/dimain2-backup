CREATE TABLE [Derived].[IronOffer_PartnerCommissionRule] (
    [PCR_ID]                    INT        NOT NULL,
    [PartnerID]                 INT        NULL,
    [TypeID]                    INT        NULL,
    [CommissionRate]            FLOAT (53) NULL,
    [Status]                    BIT        NULL,
    [Priority]                  INT        NULL,
    [DeletionDate]              DATETIME   NULL,
    [MaximumUsesPerFan]         INT        NULL,
    [NumberofPriorTransactions] INT        NULL,
    [MinimumBasketSize]         FLOAT (53) NULL,
    [MaximumBasketSize]         FLOAT (53) NULL,
    [Channel]                   INT        NULL,
    [ClubID]                    INT        NULL,
    [IronOfferID]               INT        NULL,
    [OutletID]                  INT        NULL,
    [CardHolderPresence]        INT        NULL,
    PRIMARY KEY CLUSTERED ([PCR_ID] ASC)
);

