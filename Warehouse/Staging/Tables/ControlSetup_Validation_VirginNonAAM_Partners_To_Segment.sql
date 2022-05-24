CREATE TABLE [Staging].[ControlSetup_Validation_VirginNonAAM_Partners_To_Segment] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [PublisherType]  VARCHAR (50) NULL,
    [PartnerID]      INT          NULL,
    [Segment]        VARCHAR (10) NULL,
    [ControlGroupID] INT          NULL,
    [StartDate]      DATE         NULL,
    [EndDate]        DATE         NULL,
    CONSTRAINT [PK_ControlSetup_Validation_VirginNonAAM_Partners_To_Segment] PRIMARY KEY CLUSTERED ([ID] ASC)
);

