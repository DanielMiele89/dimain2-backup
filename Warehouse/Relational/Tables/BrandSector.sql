﻿CREATE TABLE [Relational].[BrandSector] (
    [SectorID]      TINYINT      IDENTITY (1, 1) NOT NULL,
    [SectorGroupID] TINYINT      NOT NULL,
    [SectorName]    VARCHAR (50) NULL,
    CONSTRAINT [PK_BrandSector_v2] PRIMARY KEY CLUSTERED ([SectorGroupID] ASC, [SectorID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Relational].[BrandSector] TO [visa_etl_user]
    AS [dbo];

