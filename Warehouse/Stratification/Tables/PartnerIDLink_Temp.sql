CREATE TABLE [Stratification].[PartnerIDLink_Temp] (
    [PartnerGroupID]        INT          NULL,
    [PartnerID]             INT          NULL,
    [ActivatedPartnerID]    INT          NULL,
    [NonCore]               INT          NOT NULL,
    [ControlPartnerID]      INT          NULL,
    [BespokeStratification] INT          NOT NULL,
    [ReportMonth]           INT          NULL,
    [PartnerIDType]         VARCHAR (50) NOT NULL,
    [OOPControl]            INT          NULL,
    CONSTRAINT [uc_PersonID] UNIQUE NONCLUSTERED ([PartnerID] ASC, [PartnerGroupID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_P]
    ON [Stratification].[PartnerIDLink_Temp]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_PG]
    ON [Stratification].[PartnerIDLink_Temp]([PartnerGroupID] ASC);

