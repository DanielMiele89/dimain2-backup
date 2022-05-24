CREATE TABLE [Relational].[Customer_Segment] (
    [FanID]       INT      NOT NULL,
    [PartnerID]   INT      NOT NULL,
    [SegmentCode] CHAR (1) NULL,
    [OfferID]     INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [enddate]     DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [i_FanID]
    ON [Relational].[Customer_Segment]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [i_PartnerID]
    ON [Relational].[Customer_Segment]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [i_SegmentCode]
    ON [Relational].[Customer_Segment]([SegmentCode] ASC);

