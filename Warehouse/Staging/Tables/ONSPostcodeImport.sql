CREATE TABLE [Staging].[ONSPostcodeImport] (
    [Postcode]   VARCHAR (8)   NOT NULL,
    [Town]       VARCHAR (100) NULL,
    [TownRegion] VARCHAR (100) NULL,
    [Region]     VARCHAR (30)  NULL,
    CONSTRAINT [PK_ONSPostcodeImport] PRIMARY KEY CLUSTERED ([Postcode] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Staging].[ONSPostcodeImport] TO [visa_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Staging].[ONSPostcodeImport] TO [virgin_etl_user]
    AS [dbo];

