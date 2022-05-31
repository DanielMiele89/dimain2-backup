CREATE TABLE [Rory].[OfferReport_MatchCustomers] (
    [IronOfferCyclesID] INT NOT NULL,
    [FanID]             INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_IOC]
    ON [Rory].[OfferReport_MatchCustomers]([IronOfferCyclesID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90);

