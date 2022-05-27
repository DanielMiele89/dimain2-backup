CREATE TABLE [InsightArchive].[MosaicBPLookup] (
    [Postcode]          VARCHAR (50) NULL,
    [ID]                VARCHAR (50) NULL,
    [Experian Postcode] VARCHAR (50) NULL,
    [Mosaic UK Group]   VARCHAR (50) NULL,
    [Mosaic UK Type]    VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [IND_UKT]
    ON [InsightArchive].[MosaicBPLookup]([Mosaic UK Type] ASC);

