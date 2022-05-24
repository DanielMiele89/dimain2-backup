CREATE TABLE [InsightArchive].[Salespack_store_postcodes] (
    [postcode]     VARCHAR (50) NOT NULL,
    [main_brand]   VARCHAR (50) NOT NULL,
    [IsOnline]     BIT          NOT NULL,
    [spend]        MONEY        NULL,
    [transactions] INT          NULL,
    [customers]    INT          NULL
);

