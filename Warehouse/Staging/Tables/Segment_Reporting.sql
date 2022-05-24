CREATE TABLE [Staging].[Segment_Reporting] (
    [FanID]       INT         NOT NULL,
    [PartnerID]   INT         NOT NULL,
    [SegmentCode] VARCHAR (1) NULL
);


GO
CREATE NONCLUSTERED INDEX [i_SegmentCode]
    ON [Staging].[Segment_Reporting]([SegmentCode] ASC);


GO
CREATE NONCLUSTERED INDEX [i_PartnerID]
    ON [Staging].[Segment_Reporting]([PartnerID] ASC);


GO
CREATE CLUSTERED INDEX [i_FanID]
    ON [Staging].[Segment_Reporting]([FanID] ASC);

