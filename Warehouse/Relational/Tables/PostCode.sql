CREATE TABLE [Relational].[PostCode] (
    [Postcode]   VARCHAR (8) NOT NULL,
    [PostOuter]  VARCHAR (4) NULL,
    [PostSector] VARCHAR (6) NULL,
    [Easting]    INT         NULL,
    [Northing]   INT         NULL,
    CONSTRAINT [PK_PostCode1] PRIMARY KEY CLUSTERED ([Postcode] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_PostOuter]
    ON [Relational].[PostCode]([PostOuter] ASC);


GO
CREATE NONCLUSTERED INDEX [i_PostSector]
    ON [Relational].[PostCode]([PostSector] ASC);


GO
CREATE NONCLUSTERED INDEX [i_Easting]
    ON [Relational].[PostCode]([Easting] ASC);


GO
CREATE NONCLUSTERED INDEX [i_Northing]
    ON [Relational].[PostCode]([Northing] ASC);

