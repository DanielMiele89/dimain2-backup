CREATE TABLE [COD].[CommissionRule] (
    [ID]            INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [OfferID]       INT        NOT NULL,
    [MarketingRate] FLOAT (53) NOT NULL,
    [BillingRate]   FLOAT (53) NOT NULL,
    CONSTRAINT [PK__Commissi__3214EC27DEEF74E2] PRIMARY KEY CLUSTERED ([ID] ASC)
);

