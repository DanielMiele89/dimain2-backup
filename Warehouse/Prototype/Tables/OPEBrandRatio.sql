CREATE TABLE [Prototype].[OPEBrandRatio] (
    [ID]        INT        IDENTITY (1, 1) NOT NULL,
    [BrandID]   SMALLINT   NOT NULL,
    [PropClass] TINYINT    NOT NULL,
    [Ratio]     FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

