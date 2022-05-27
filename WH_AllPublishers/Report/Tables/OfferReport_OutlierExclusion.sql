CREATE TABLE [Report].[OfferReport_OutlierExclusion] (
    [BrandID]    INT   NOT NULL,
    [UpperValue] MONEY NOT NULL,
    [RetailerID] INT   NOT NULL,
    [StartDate]  DATE  DEFAULT (getdate()) NOT NULL,
    [EndDate]    DATE  NULL
);

