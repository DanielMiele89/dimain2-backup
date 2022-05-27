CREATE TABLE [InsightArchive].[Halfords_Quidco_CTA_Offer_12071_Control] (
    [FanID]   INT         NOT NULL,
    [Segment] VARCHAR (7) NULL
);


GO
CREATE CLUSTERED INDEX [cix_Halfords_Quidco_CTA_Offer_12071_Control_FanID]
    ON [InsightArchive].[Halfords_Quidco_CTA_Offer_12071_Control]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [cix_Halfords_Quidco_CTA_Offer_12071_Control_Segment]
    ON [InsightArchive].[Halfords_Quidco_CTA_Offer_12071_Control]([Segment] ASC);

