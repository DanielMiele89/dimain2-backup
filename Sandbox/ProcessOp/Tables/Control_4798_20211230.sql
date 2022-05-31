CREATE TABLE [ProcessOp].[Control_4798_20211230] (
    [FanID]     INT          NULL,
    [CINID]     INT          NULL,
    [PartnerID] VARCHAR (10) NULL,
    [SegmentID] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SegmentIDFanID]
    ON [ProcessOp].[Control_4798_20211230]([SegmentID] ASC, [FanID] ASC);

