CREATE TABLE [Staging].[CAMEO_Staging] (
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
    CONSTRAINT [pk_CAMEO_Staging_PostCode] PRIMARY KEY CLUSTERED ([Postcode] ASC)
);

