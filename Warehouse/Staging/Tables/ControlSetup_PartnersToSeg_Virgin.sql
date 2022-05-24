CREATE TABLE [Staging].[ControlSetup_PartnersToSeg_Virgin] (
    [ControlGroupID] INT          NOT NULL,
    [PartnerID]      INT          NOT NULL,
    [StartDate]      DATETIME     NOT NULL,
    [EndDate]        DATETIME     NOT NULL,
    [Segment]        VARCHAR (50) NULL,
    CONSTRAINT [PK_ControlSetup_PartnersToSeg_Virgin] PRIMARY KEY CLUSTERED ([ControlGroupID] ASC, [PartnerID] ASC, [StartDate] ASC, [EndDate] ASC)
);

