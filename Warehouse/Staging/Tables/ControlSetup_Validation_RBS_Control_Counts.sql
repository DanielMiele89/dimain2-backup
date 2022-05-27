CREATE TABLE [Staging].[ControlSetup_Validation_RBS_Control_Counts] (
    [PublisherType]  VARCHAR (50) NULL,
    [PartnerID]      INT          NOT NULL,
    [SuperSegmentID] TINYINT      NULL,
    [SegmentName]    VARCHAR (50) NULL,
    [ControlGroupID] INT          NOT NULL,
    [StartDate]      DATE         NOT NULL,
    [NumberofFanIDs] INT          NULL,
    CONSTRAINT [PK_ControlSetup_Validation_RBS_Control_Counts] PRIMARY KEY CLUSTERED ([PartnerID] ASC, [ControlGroupID] ASC, [StartDate] ASC)
);

