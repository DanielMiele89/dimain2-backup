CREATE TABLE [dbo].[RedemptionItem] (
    [RedemptionItemID]      INT            IDENTITY (1, 1) NOT NULL,
    [RedemptionType]        VARCHAR (15)   NOT NULL,
    [RedemptionDescription] VARCHAR (100)  NULL,
    [RedemptionPartnerID]   INT            NOT NULL,
    [CashbackRequired]      DECIMAL (6, 2) NULL,
    [TradeUpValue]          DECIMAL (6, 2) NULL,
    [SourceTypeID]          SMALLINT       NOT NULL,
    [SourceID]              VARCHAR (36)   NOT NULL,
    [CreatedDateTime]       DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]       DATETIME2 (7)  NULL,
    [MD5]                   VARBINARY (16) NOT NULL,
    [CashbackRate]          DECIMAL (5, 2) NULL,
    CONSTRAINT [PK_RedemptionItem] PRIMARY KEY CLUSTERED ([RedemptionItemID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_RedemptionItem_RedemptionPartnerID] FOREIGN KEY ([RedemptionPartnerID]) REFERENCES [dbo].[RedemptionPartner] ([RedemptionPartnerID]),
    CONSTRAINT [FK_RedemptionItem_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_RedemptionItem_Source]
    ON [dbo].[RedemptionItem]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

