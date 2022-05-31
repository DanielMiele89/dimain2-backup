CREATE TABLE [ProcessOp].[Control_4980_20220210] (
    [FanID]     INT          NULL,
    [CINID]     INT          NULL,
    [PartnerID] VARCHAR (10) NULL,
    [SegmentID] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SegmentIDFanID]
    ON [ProcessOp].[Control_4980_20220210]([SegmentID] ASC, [FanID] ASC);

