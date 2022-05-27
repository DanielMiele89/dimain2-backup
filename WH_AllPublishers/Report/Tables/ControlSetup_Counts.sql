CREATE TABLE [Report].[ControlSetup_Counts] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [PublisherType]       VARCHAR (40)  NULL,
    [PartnerID]           INT           NULL,
    [OfferTypeForReports] VARCHAR (100) NULL,
    [InIronOfferCycles]   BIT           NULL,
    [ControlGroupID]      INT           NULL,
    [NumberofFanIDs]      INT           NULL,
    [StartDate]           DATE          NULL,
    [ControlGroupTypeID]  INT           NULL,
    [ReportDate]          DATE          NULL,
    CONSTRAINT [PK_ControlsBI_ControlSetup_Counts] PRIMARY KEY CLUSTERED ([ID] ASC)
);

