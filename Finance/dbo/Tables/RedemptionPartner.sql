CREATE TABLE [dbo].[RedemptionPartner] (
    [RedemptionPartnerID]   INT            IDENTITY (1, 1) NOT NULL,
    [RedemptionPartnerName] VARCHAR (100)  NOT NULL,
    [SourceTypeID]          SMALLINT       NOT NULL,
    [SourceID]              VARCHAR (36)   NOT NULL,
    [CreatedDateTime]       DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]       DATETIME2 (7)  NULL,
    [MD5]                   VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_RedemptionPartner] PRIMARY KEY CLUSTERED ([RedemptionPartnerID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_RedemptionPartner_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_RedemptionPartner_Source]
    ON [dbo].[RedemptionPartner]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

