CREATE TABLE [InsightArchive].[HB004_PreSelection] (
    [fanid]             INT          NOT NULL,
    [cinid]             INT          NOT NULL,
    [Gender]            VARCHAR (1)  NULL,
    [PostalSector]      VARCHAR (30) NULL,
    [Age_Group]         VARCHAR (12) NULL,
    [CAMEO_CODE_GRP]    VARCHAR (50) NULL,
    [Region]            VARCHAR (25) NULL,
    [MarketableByEmail] TINYINT      NULL,
    [Target_DT]         FLOAT (53)   NULL,
    [ComboID_2]         BIGINT       NULL,
    [Index_RR]          REAL         NULL,
    [UnknownGroup]      INT          NULL,
    [Response_Index]    REAL         NULL
);

