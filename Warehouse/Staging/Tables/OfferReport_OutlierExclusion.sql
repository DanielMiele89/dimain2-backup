CREATE TABLE [Staging].[OfferReport_OutlierExclusion] (
    [BrandID]    INT   NOT NULL,
    [UpperValue] MONEY NOT NULL,
    [PartnerID]  INT   NOT NULL,
    [StartDate]  DATE  CONSTRAINT [DF__OfferRepo__Start__7FB7ED56] DEFAULT ('2012-01-01') NOT NULL,
    [EndDate]    DATE  DEFAULT ('2050-01-01') NULL
);


GO
CREATE CLUSTERED INDEX [CIX_PartnerStart]
    ON [Staging].[OfferReport_OutlierExclusion]([PartnerID] ASC, [StartDate] ASC, [EndDate] ASC);

