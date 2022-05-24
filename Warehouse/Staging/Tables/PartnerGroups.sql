CREATE TABLE [Staging].[PartnerGroups] (
    [PartnerGroupID]   INT          NOT NULL,
    [PartnerGroupName] VARCHAR (12) NOT NULL,
    [PartnerID]        INT          NOT NULL,
    [UseForReport]     INT          NOT NULL,
    [DefaultEPOCU]     INT          NULL
);

