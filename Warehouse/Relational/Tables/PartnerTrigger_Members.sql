CREATE TABLE [Relational].[PartnerTrigger_Members] (
    [MemberID]   INT IDENTITY (1, 1) NOT NULL,
    [FanID]      INT NULL,
    [CampaignID] INT NULL,
    CONSTRAINT [pk_MemID] PRIMARY KEY CLUSTERED ([MemberID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CampID]
    ON [Relational].[PartnerTrigger_Members]([CampaignID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[PartnerTrigger_Members]([FanID] ASC);

