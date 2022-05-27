CREATE TABLE [Staging].[OfferReport_OutlierExclusion_Checks] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]            INT          NULL,
    [PartnerID]          INT          NULL,
    [PartnerName]        VARCHAR (50) NULL,
    [TotalSales]         MONEY        NULL,
    [ExcludedSales]      MONEY        NULL,
    [PercentageExcluded] FLOAT (53)   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

