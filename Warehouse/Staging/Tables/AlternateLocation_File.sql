CREATE TABLE [Staging].[AlternateLocation_File] (
    [ID]              INT           IDENTITY (1, 1) NOT NULL,
    [MIDNumeric]      VARCHAR (50)  NOT NULL,
    [Narrative]       VARCHAR (50)  NOT NULL,
    [Postcode]        VARCHAR (50)  NOT NULL,
    [MIDNAMEPOSTCODE] VARCHAR (200) NOT NULL,
    [Format]          VARCHAR (50)  NOT NULL,
    [Category]        VARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_Staging_AlternateLocation] PRIMARY KEY CLUSTERED ([ID] ASC)
);

