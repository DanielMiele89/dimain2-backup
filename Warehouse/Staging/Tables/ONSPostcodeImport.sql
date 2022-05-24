CREATE TABLE [Staging].[ONSPostcodeImport] (
    [Postcode]   VARCHAR (8)   NOT NULL,
    [Town]       VARCHAR (100) NULL,
    [TownRegion] VARCHAR (100) NULL,
    [Region]     VARCHAR (30)  NULL,
    CONSTRAINT [PK_ONSPostcodeImport] PRIMARY KEY CLUSTERED ([Postcode] ASC)
);

