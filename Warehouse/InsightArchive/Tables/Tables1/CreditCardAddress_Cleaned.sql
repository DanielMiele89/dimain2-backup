CREATE TABLE [InsightArchive].[CreditCardAddress_Cleaned] (
    [id]                INT           IDENTITY (1, 1) NOT NULL,
    [MID]               VARCHAR (50)  NOT NULL,
    [Narrative]         VARCHAR (100) NOT NULL,
    [MCCID]             SMALLINT      NOT NULL,
    [LocationCountry]   VARCHAR (2)   NOT NULL,
    [Town]              VARCHAR (50)  NOT NULL,
    [PostCode]          VARCHAR (10)  NOT NULL,
    [IsValidUKPostCode] BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

