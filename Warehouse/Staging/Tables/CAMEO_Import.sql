CREATE TABLE [Staging].[CAMEO_Import] (
    [Postcode_New]                VARCHAR (50) NOT NULL,
    [GRE_New]                     VARCHAR (50) NULL,
    [GRN_New]                     VARCHAR (50) NULL,
    [CAMEO_CODE_New]              VARCHAR (50) NULL,
    [CAMEO_CODE_GROUP_New]        VARCHAR (50) NULL,
    [CAMEO_INTL_New]              VARCHAR (50) NULL,
    [PostalSector_New]            VARCHAR (50) NULL,
    [PostalDistrict_New]          VARCHAR (50) NULL,
    [PostalArea_New]              VARCHAR (50) NULL,
    [Postcodestatusindicator_New] VARCHAR (50) NULL,
    CONSTRAINT [pk_CAMEO_Import_Postcode] PRIMARY KEY CLUSTERED ([Postcode_New] ASC)
);

