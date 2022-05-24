CREATE TABLE [Staging].[ALS_Anchor_Cycle_Member_nFI] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [PublisherID]      INT          NULL,
    [PartnerID]        INT          NULL,
    [FanID]            INT          NULL,
    [SuperSegmentName] VARCHAR (50) NULL,
    CONSTRAINT [PK_ALS_Anchor_Cycle_Member_nFI] PRIMARY KEY CLUSTERED ([ID] ASC)
);

