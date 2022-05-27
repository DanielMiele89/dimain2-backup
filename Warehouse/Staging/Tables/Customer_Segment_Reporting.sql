CREATE TABLE [Staging].[Customer_Segment_Reporting] (
    [FanID]       INT         NOT NULL,
    [PartnerID]   INT         NOT NULL,
    [SegmentCode] VARCHAR (1) NULL,
    [OfferID]     INT         NOT NULL,
    [StartDate]   DATETIME    NOT NULL,
    [EndDate]     DATETIME    NULL
);

