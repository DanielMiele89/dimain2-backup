CREATE TABLE [InsightArchive].[Halfords_Quidco_CTA_Offer_12071] (
    [FanID]   INT         NOT NULL,
    [Segment] VARCHAR (7) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [cix_Halfords_Quidco_CTA_Offer_12071_Segment]
    ON [InsightArchive].[Halfords_Quidco_CTA_Offer_12071]([Segment] ASC);


GO
CREATE CLUSTERED INDEX [cix_Halfords_Quidco_CTA_Offer_12071_FanID]
    ON [InsightArchive].[Halfords_Quidco_CTA_Offer_12071]([FanID] ASC);

