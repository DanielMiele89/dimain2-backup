CREATE TABLE [Staging].[ControlSetup_PartnersToSeg_nFI] (
    [RowNo]     INT          NOT NULL,
    [PartnerID] INT          NOT NULL,
    [StartDate] DATETIME     NOT NULL,
    [EndDate]   DATETIME     NOT NULL,
    [Segment]   VARCHAR (50) NULL,
    CONSTRAINT [PK_ControlSetup_PartnersToSeg_nFI] PRIMARY KEY CLUSTERED ([RowNo] ASC, [PartnerID] ASC, [StartDate] ASC, [EndDate] ASC)
);

