CREATE TABLE [Staging].[ControlSetup_PartnersToSeg_Warehouse] (
    [RowNo]     INT          NOT NULL,
    [PartnerID] INT          NOT NULL,
    [StartDate] DATETIME     NOT NULL,
    [EndDate]   DATETIME     NOT NULL,
    [Segment]   VARCHAR (50) NULL,
    CONSTRAINT [PK_ControlSetup_PartnersToSeg_Warehouse] PRIMARY KEY CLUSTERED ([RowNo] ASC, [PartnerID] ASC, [StartDate] ASC, [EndDate] ASC)
);

