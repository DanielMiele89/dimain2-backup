CREATE TABLE [PatrickM].[testvalues] (
    [FanID]       INT              NOT NULL,
    [CompositeID] BIGINT           NULL,
    [HeatmapID]   BIGINT           NULL,
    [BrandID]     INT              NULL,
    [PartnerID]   INT              NOT NULL,
    [Type]        VARCHAR (7)      NOT NULL,
    [PremiumFlag] INT              NOT NULL,
    [Propensity]  NUMERIC (25, 13) NULL
);

