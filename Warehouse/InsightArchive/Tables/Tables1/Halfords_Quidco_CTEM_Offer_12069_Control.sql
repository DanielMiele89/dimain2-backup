CREATE TABLE [InsightArchive].[Halfords_Quidco_CTEM_Offer_12069_Control] (
    [FanID]   INT         NULL,
    [Segment] VARCHAR (7) NULL
);


GO
CREATE CLUSTERED INDEX [cix_Halfords_Quidco_CTEM_Offer_12069_Control_FanID]
    ON [InsightArchive].[Halfords_Quidco_CTEM_Offer_12069_Control]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [cix_Halfords_Quidco_CTEM_Offer_12069_Control_Segment]
    ON [InsightArchive].[Halfords_Quidco_CTEM_Offer_12069_Control]([Segment] ASC);

