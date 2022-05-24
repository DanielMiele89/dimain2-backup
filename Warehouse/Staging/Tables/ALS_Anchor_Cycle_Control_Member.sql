CREATE TABLE [Staging].[ALS_Anchor_Cycle_Control_Member] (
    [ID]                 INT IDENTITY (1, 1) NOT NULL,
    [PartnerID]          INT NULL,
    [SuperSegmentTypeID] INT NULL,
    [FanID]              INT NULL,
    CONSTRAINT [PK_ALS_Anchor_Cycle_Control_Member] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ALS_Anchor_Cycle_Control_Member]
    ON [Staging].[ALS_Anchor_Cycle_Control_Member]([PartnerID] ASC, [FanID] ASC)
    INCLUDE([SuperSegmentTypeID]);

