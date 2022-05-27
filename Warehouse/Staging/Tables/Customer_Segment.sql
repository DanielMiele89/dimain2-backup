CREATE TABLE [Staging].[Customer_Segment] (
    [FanID]       INT      NOT NULL,
    [PartnerID]   INT      NOT NULL,
    [SegmentCode] CHAR (1) NULL,
    [OfferID]     INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [enddate]     DATETIME NULL
);

