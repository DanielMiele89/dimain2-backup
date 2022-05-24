CREATE TABLE [Staging].[ALS_SlowlyChangingDimension_nFI] (
    [ID]                 INT  IDENTITY (1, 1) NOT NULL,
    [SuperSegmentTypeID] INT  NULL,
    [PartnerID]          INT  NULL,
    [FanID]              INT  NULL,
    [StartDate]          DATE NULL,
    [EndDate]            DATE NULL,
    CONSTRAINT [PK_ALS_SlowlyChangingDimension_nFI] PRIMARY KEY CLUSTERED ([ID] ASC)
);

