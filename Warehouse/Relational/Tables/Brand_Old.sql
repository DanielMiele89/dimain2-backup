CREATE TABLE [Relational].[Brand_Old] (
    [BrandID]           SMALLINT     IDENTITY (1, 1) NOT NULL,
    [BrandName]         VARCHAR (50) NOT NULL,
    [IsLivePartner]     BIT          DEFAULT ((0)) NOT NULL,
    [BrandGroupID]      TINYINT      NULL,
    [SectorID]          TINYINT      NULL,
    [IsHighRisk]        BIT          DEFAULT ((0)) NOT NULL,
    [IsNamedException]  BIT          DEFAULT ((0)) NOT NULL,
    [ChargeOnRedeem]    BIT          CONSTRAINT [DF_Relational_Brand_ChargeOnRedeem] DEFAULT ((0)) NOT NULL,
    [IsOnlineOnly]      BIT          NULL,
    [IsPremiumRetailer] BIT          NULL,
    CONSTRAINT [PK_Brand_Relational] PRIMARY KEY CLUSTERED ([BrandID] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [FK_Brand_BrandGroup] FOREIGN KEY ([BrandGroupID]) REFERENCES [Relational].[BrandGroup] ([BrandGroupID]),
    CONSTRAINT [FK_Relational_Brand_BrandSector] FOREIGN KEY ([SectorID]) REFERENCES [Relational].[BrandSector_Old] ([SectorID]),
    CONSTRAINT [UQ_Brand_BrandName] UNIQUE NONCLUSTERED ([BrandName] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_Brand_IsLivePartner]
    ON [Relational].[Brand_Old]([IsLivePartner] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Brand_SectorID]
    ON [Relational].[Brand_Old]([SectorID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Brand_BrandGroup]
    ON [Relational].[Brand_Old]([BrandGroupID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_Brand_BrandName]
    ON [Relational].[Brand_Old]([BrandName] ASC) WITH (FILLFACTOR = 80);


GO
GRANT UPDATE
    ON OBJECT::[Relational].[Brand_Old] TO [New_Branding]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Relational].[Brand_Old] TO [New_Branding]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[Brand_Old] TO [New_Branding]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Relational].[Brand_Old] TO [New_Branding]
    AS [dbo];

