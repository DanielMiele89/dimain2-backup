CREATE TABLE [Staging].[ControlSetup_PartnersToSeg_VirginPCA] (
    [ControlGroupID] INT          NOT NULL,
    [PartnerID]      INT          NOT NULL,
    [StartDate]      DATE         NOT NULL,
    [EndDate]        DATE         NOT NULL,
    [Segment]        VARCHAR (50) NULL,
    CONSTRAINT [PK_ControlSetup_PartnersToSeg_VirginPCA] PRIMARY KEY CLUSTERED ([ControlGroupID] ASC, [PartnerID] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90)
);

