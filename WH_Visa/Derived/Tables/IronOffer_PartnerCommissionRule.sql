CREATE TABLE [Derived].[IronOffer_PartnerCommissionRule] (
    [PCR_ID]                    VARCHAR (64)    NOT NULL,
    [PartnerID]                 INT             NULL,
    [TypeID]                    INT             NULL,
    [RewardType]                VARCHAR (10)    NOT NULL,
    [CommissionRate]            DECIMAL (19, 4) NULL,
    [Override]                  DECIMAL (19, 4) NULL,
    [Status]                    BIT             NULL,
    [Priority]                  INT             NULL,
    [DeletionDate]              DATETIME        NULL,
    [MaximumUsesPerFan]         INT             NULL,
    [NumberofPriorTransactions] INT             NULL,
    [MinimumBasketSize]         DECIMAL (19, 4) NULL,
    [MaximumBasketSize]         DECIMAL (19, 4) NULL,
    [Channel]                   INT             NULL,
    [ClubID]                    INT             NULL,
    [IronOfferID]               INT             NULL,
    [OutletID]                  INT             NULL,
    [CardHolderPresence]        INT             NULL,
    [OfferCap]                  DECIMAL (19, 4) NULL
);

