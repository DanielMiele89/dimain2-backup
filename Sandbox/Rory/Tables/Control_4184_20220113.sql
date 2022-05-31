CREATE TABLE [Rory].[Control_4184_20220113] (
    [FanID]     INT          NULL,
    [CINID]     INT          NULL,
    [PartnerID] VARCHAR (10) NULL,
    [SegmentID] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SegmentIDFanID]
    ON [Rory].[Control_4184_20220113]([SegmentID] ASC, [FanID] ASC);

