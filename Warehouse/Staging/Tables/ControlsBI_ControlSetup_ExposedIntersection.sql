CREATE TABLE [Staging].[ControlsBI_ControlSetup_ExposedIntersection] (
    [ID]                              INT           IDENTITY (1, 1) NOT NULL,
    [StartDate]                       DATE          NULL,
    [PublisherType]                   VARCHAR (40)  NULL,
    [IronOfferID]                     INT           NULL,
    [OfferTypeForReports]             VARCHAR (100) NULL,
    [PartnerID]                       INT           NULL,
    [ControlGroupID]                  INT           NULL,
    [ControlGroupTypeID]              INT           NULL,
    [IronOfferCyclesID]               INT           NULL,
    [ControlMembers]                  INT           NULL,
    [ExposedMembers]                  INT           NULL,
    [ControlExposedMembers]           INT           NULL,
    [ControlExposedMembersProportion] FLOAT (53)    NULL,
    [ReportDate]                      DATE          NULL,
    CONSTRAINT [PK_ControlsBI_ControlSetup_ExposedIntersection] PRIMARY KEY CLUSTERED ([ID] ASC)
);

