CREATE TABLE [dbo].[PartnerAlternate_OLD] (
    [AlternatePartnerID] INT           NOT NULL,
    [PartnerID]          INT           NOT NULL,
    [CreatedDateTime]    DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]    DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_PartnerAlternate_OLD] PRIMARY KEY CLUSTERED ([AlternatePartnerID] ASC),
    CONSTRAINT [FK_PartnerAlternate_PartnerID_OLD] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner_OLD] ([PartnerID])
);

