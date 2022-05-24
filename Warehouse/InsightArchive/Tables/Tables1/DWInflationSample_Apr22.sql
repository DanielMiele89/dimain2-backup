CREATE TABLE [InsightArchive].[DWInflationSample_Apr22] (
    [CINID]                     INT            NOT NULL,
    [FanID]                     INT            NOT NULL,
    [SourceUID]                 VARCHAR (20)   NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [CAMEO_CODE_GROUP]          VARCHAR (50)   NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NOT NULL,
    [CAMEO_CODE]                VARCHAR (50)   NULL,
    [CAMEO_CODE_Category]       NVARCHAR (255) NULL,
    [Couples]                   NVARCHAR (255) NULL,
    [Singles]                   NVARCHAR (255) NULL,
    [Families]                  NVARCHAR (255) NULL,
    [DOB]                       DATE           NULL,
    [rn]                        BIGINT         NULL
);


GO
CREATE CLUSTERED INDEX [SIX_CINID]
    ON [InsightArchive].[DWInflationSample_Apr22]([CINID] ASC) WITH (FILLFACTOR = 90);

