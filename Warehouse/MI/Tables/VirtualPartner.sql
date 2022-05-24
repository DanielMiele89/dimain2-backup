CREATE TABLE [MI].[VirtualPartner] (
    [PartnerID]          INT           NOT NULL,
    [DisplayPartnerid]   INT           NOT NULL,
    [VirtualPartnerID]   INT           NULL,
    [PartnerGroupID]     INT           NOT NULL,
    [VirtualPartnerName] VARCHAR (100) NULL,
    [UseForReport]       INT           NULL,
    CONSTRAINT [PK_MI_VirtualPartner_Partitioned] PRIMARY KEY CLUSTERED ([PartnerID] ASC, [PartnerGroupID] ASC)
);

