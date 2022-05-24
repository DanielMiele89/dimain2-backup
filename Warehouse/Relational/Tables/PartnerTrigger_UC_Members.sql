CREATE TABLE [Relational].[PartnerTrigger_UC_Members] (
    [MemberID]   INT IDENTITY (1, 1) NOT NULL,
    [FanID]      INT NULL,
    [CampaignID] INT NULL,
    CONSTRAINT [pk_MemID2] PRIMARY KEY CLUSTERED ([MemberID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CampID]
    ON [Relational].[PartnerTrigger_UC_Members]([CampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[PartnerTrigger_UC_Members]([FanID] ASC);

