CREATE TABLE [Relational].[Brand] (
    [BrandID]           SMALLINT     IDENTITY (1, 1) NOT NULL,
    [BrandName]         VARCHAR (50) NOT NULL,
    [IsLivePartner]     BIT          DEFAULT ((0)) NOT NULL,
    [BrandGroupID]      TINYINT      NULL,
    [SectorID]          TINYINT      NULL,
    [IsHighRisk]        BIT          DEFAULT ((0)) NOT NULL,
    [IsNamedException]  BIT          DEFAULT ((0)) NOT NULL,
    [ChargeOnRedeem]    BIT          NOT NULL,
    [IsOnlineOnly]      BIT          NULL,
    [IsPremiumRetailer] BIT          NULL,
    CONSTRAINT [PK_Brand_Relational_v2] PRIMARY KEY CLUSTERED ([BrandID] ASC) WITH (FILLFACTOR = 80),
    CONSTRAINT [UQ_Brand_BrandName_v2] UNIQUE NONCLUSTERED ([BrandName] ASC) WITH (FILLFACTOR = 80)
);




GO
GRANT UPDATE
    ON OBJECT::[Relational].[Brand] TO [New_Branding]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Relational].[Brand] TO [visa_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Relational].[Brand] TO [New_Branding]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Relational].[Brand] TO [New_Branding]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[Relational].[Brand] TO [New_Branding]
    AS [dbo];

