CREATE TABLE [ProcessOp].[Control_4758_20220407] (
    [FanID]     INT          NULL,
    [CINID]     INT          NULL,
    [PartnerID] VARCHAR (10) NULL,
    [SegmentID] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SegmentIDFanID]
    ON [ProcessOp].[Control_4758_20220407]([SegmentID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90);

