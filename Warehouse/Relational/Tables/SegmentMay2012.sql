CREATE TABLE [Relational].[SegmentMay2012] (
    [FanID]       INT         NOT NULL,
    [PartnerID]   INT         NOT NULL,
    [SegmentCode] VARCHAR (1) NULL
);


GO
CREATE CLUSTERED INDEX [i_FanID]
    ON [Relational].[SegmentMay2012]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [i_PartnerID]
    ON [Relational].[SegmentMay2012]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [i_SegmentCode]
    ON [Relational].[SegmentMay2012]([SegmentCode] ASC);

