CREATE TABLE [MI].[PostCodesLKP] (
    [Postcode]     VARCHAR (8)  NOT NULL,
    [PostSector]   VARCHAR (6)  NULL,
    [PostDistrict] VARCHAR (4)  NULL,
    [PostArea]     VARCHAR (2)  NULL,
    [Region]       VARCHAR (30) NULL,
    [Easting]      INT          NULL,
    [Northing]     INT          NULL,
    CONSTRAINT [PK_MI_PostCodesLKP] PRIMARY KEY CLUSTERED ([Postcode] ASC)
);

