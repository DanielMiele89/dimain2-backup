CREATE TABLE [Relational].[SegmentFullCleanedApril2012] (
    [FanID]       INT         NOT NULL,
    [PartnerID]   INT         NOT NULL,
    [SegmentCode] VARCHAR (1) NULL
);


GO
CREATE NONCLUSTERED INDEX [i_SegmentCode]
    ON [Relational].[SegmentFullCleanedApril2012]([SegmentCode] ASC);


GO
CREATE NONCLUSTERED INDEX [i_PartnerID]
    ON [Relational].[SegmentFullCleanedApril2012]([PartnerID] ASC);


GO
CREATE CLUSTERED INDEX [i_FanID]
    ON [Relational].[SegmentFullCleanedApril2012]([FanID] ASC);

