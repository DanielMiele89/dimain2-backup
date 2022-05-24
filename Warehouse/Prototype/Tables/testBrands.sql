CREATE TABLE [Prototype].[testBrands] (
    [BrandID]          SMALLINT     IDENTITY (1, 1) NOT NULL,
    [BrandName]        VARCHAR (50) NOT NULL,
    [IsLivePartner]    BIT          NOT NULL,
    [BrandGroupID]     TINYINT      NULL,
    [SectorID]         TINYINT      NULL,
    [IsHighRisk]       BIT          NOT NULL,
    [IsNamedException] BIT          NOT NULL,
    [ChargeOnRedeem]   BIT          NOT NULL
);

