CREATE TABLE [InsightArchive].[Halfords_Quidco_CTEM_Offer_12069] (
    [FanID]   INT         NOT NULL,
    [Segment] VARCHAR (7) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [cix_Halfords_Quidco_CTEM_Offer_12069_Segment]
    ON [InsightArchive].[Halfords_Quidco_CTEM_Offer_12069]([Segment] ASC);


GO
CREATE CLUSTERED INDEX [cix_Halfords_Quidco_CTEM_Offer_12069_FanID]
    ON [InsightArchive].[Halfords_Quidco_CTEM_Offer_12069]([FanID] ASC);

