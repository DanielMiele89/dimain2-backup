CREATE TABLE [Derived].[__Customer_Segment_Archived] (
    [FanID]       INT      NOT NULL,
    [PartnerID]   INT      NOT NULL,
    [SegmentCode] CHAR (1) NULL,
    [OfferID]     INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [enddate]     DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [cx_CS]
    ON [Derived].[__Customer_Segment_Archived]([FanID] ASC, [PartnerID] ASC);

