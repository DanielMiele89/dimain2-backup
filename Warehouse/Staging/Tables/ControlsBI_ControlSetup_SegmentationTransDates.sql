CREATE TABLE [Staging].[ControlsBI_ControlSetup_SegmentationTransDates] (
    [ID]                           INT          IDENTITY (1, 1) NOT NULL,
    [StartDate]                    DATE         NULL,
    [PublisherType]                VARCHAR (40) NULL,
    [PartnerID]                    INT          NULL,
    [ControlGroupID]               INT          NULL,
    [ControlGroupTypeID]           INT          NULL,
    [ControlGroupSuperSegment]     VARCHAR (40) NULL,
    [MaxSpendDateForSegment]       DATE         NULL,
    [SpendersOverSegThresholdDate] INT          NULL,
    [ReportDate]                   DATE         NULL,
    CONSTRAINT [PK_ControlsBI_ControlSetup_SegmentationTransDates] PRIMARY KEY CLUSTERED ([ID] ASC)
);

