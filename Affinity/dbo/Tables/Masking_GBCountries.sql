CREATE TABLE [dbo].[Masking_GBCountries] (
    [CountryCode] VARCHAR (2) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_tempdb_gbcountries]
    ON [dbo].[Masking_GBCountries]([CountryCode] ASC);

