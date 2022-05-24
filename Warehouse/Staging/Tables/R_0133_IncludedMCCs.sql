CREATE TABLE [Staging].[R_0133_IncludedMCCs] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]   SMALLINT     NULL,
    [BrandName] VARCHAR (50) NULL,
    [MCC]       VARCHAR (4)  NULL,
    [MCCDesc]   VARCHAR (50) NULL
);

