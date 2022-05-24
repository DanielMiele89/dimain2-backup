CREATE TABLE [MI].[VirtualPartnerList_old] (
    [PartnerID]          INT           NOT NULL,
    [DisplayPartnerid]   INT           IDENTITY (100, 1) NOT NULL,
    [PartnerGroupID]     INT           NOT NULL,
    [VirtualPartnerName] VARCHAR (100) NULL,
    [UseForReport]       INT           NOT NULL
);

