CREATE TABLE [Staging].[OfferReport_AllOffers_Distinct] (
    [ID]             INT   IDENTITY (1, 1) NOT NULL,
    [GroupID]        INT   NULL,
    [StartDate]      DATE  NOT NULL,
    [EndDate]        DATE  NOT NULL,
    [isWarehouse]    BIT   NULL,
    [Exposed]        BIT   NOT NULL,
    [PartnerID]      INT   NOT NULL,
    [offerStartDate] DATE  NOT NULL,
    [offerEndDate]   DATE  NOT NULL,
    [SpendStretch]   MONEY NULL
);


GO
CREATE CLUSTERED INDEX [CIX_Group]
    ON [Staging].[OfferReport_AllOffers_Distinct]([GroupID] ASC, [Exposed] ASC, [isWarehouse] ASC, [StartDate] ASC, [EndDate] ASC);

