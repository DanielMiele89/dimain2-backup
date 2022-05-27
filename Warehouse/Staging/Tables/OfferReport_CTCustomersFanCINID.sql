CREATE TABLE [Staging].[OfferReport_CTCustomersFanCINID] (
    [GroupID]     INT NOT NULL,
    [FanID]       INT NOT NULL,
    [CINID]       INT NULL,
    [Exposed]     BIT NOT NULL,
    [PublisherID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CINEx]
    ON [Staging].[OfferReport_CTCustomersFanCINID]([CINID] ASC, [GroupID] ASC, [Exposed] ASC, [PublisherID] ASC);

