CREATE TABLE [Staging].[ControlSetup_PartnersToSeg_VisaBarclaycard] (
    [ControlGroupID] INT          NOT NULL,
    [PartnerID]      INT          NOT NULL,
    [StartDate]      DATETIME     NOT NULL,
    [EndDate]        DATETIME     NOT NULL,
    [Segment]        VARCHAR (50) NULL,
    CONSTRAINT [PK_ControlSetup_PartnersToSeg_VisaBarclaycard] PRIMARY KEY CLUSTERED ([ControlGroupID] ASC, [PartnerID] ASC, [StartDate] ASC, [EndDate] ASC)
);

