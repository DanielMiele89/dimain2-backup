CREATE TABLE [ProcessOp].[Control_4912_20220310] (
    [FanID]     INT          NULL,
    [CINID]     INT          NULL,
    [PartnerID] VARCHAR (10) NULL,
    [SegmentID] INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_SegmentIDFanID]
    ON [ProcessOp].[Control_4912_20220310]([SegmentID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90);

