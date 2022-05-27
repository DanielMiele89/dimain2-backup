CREATE TABLE [Report].[OfferReport_MatchCustomers] (
    [GroupID]           INT NOT NULL,
    [FanID]             INT NOT NULL,
    [Exposed]           BIT DEFAULT ((1)) NOT NULL,
    [isWarehouse]       BIT NULL,
    [IsVirgin]          BIT NULL,
    [IsVisaBarclaycard] BIT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Report].[OfferReport_MatchCustomers]([isWarehouse] ASC, [IsVirgin] ASC, [IsVisaBarclaycard] ASC, [Exposed] ASC, [FanID] ASC)
    INCLUDE([GroupID]);

