﻿CREATE TABLE [Relational].[CAMEO_PreNov2018] (
    [Postcode]         VARCHAR (50) NOT NULL,
    [GRE]              VARCHAR (50) NULL,
    [GRN]              VARCHAR (50) NULL,
    [CAMEO_CODE]       VARCHAR (50) NULL,
    [CAMEO_CODE_GROUP] VARCHAR (50) NULL,
    [CAMEO_INTL]       VARCHAR (50) NULL,
    [PostalSector]     VARCHAR (50) NULL,
    [PostalDistrict]   VARCHAR (50) NULL,
    [PostalArea]       VARCHAR (50) NULL,
    [PCDSTATUS]        VARCHAR (50) NULL,
    CONSTRAINT [pk_PostCode2] PRIMARY KEY CLUSTERED ([Postcode] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_CCODE2]
    ON [Relational].[CAMEO_PreNov2018]([CAMEO_CODE] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IDX_CCGROUP2]
    ON [Relational].[CAMEO_PreNov2018]([CAMEO_CODE_GROUP] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IDX_CCINTL2]
    ON [Relational].[CAMEO_PreNov2018]([CAMEO_INTL] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IDX_PS2]
    ON [Relational].[CAMEO_PreNov2018]([PostalSector] ASC) WITH (FILLFACTOR = 80);
