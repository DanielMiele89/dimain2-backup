CREATE TABLE [Prototype].[BrandMatchResults] (
    [BrandID_CC]          SMALLINT     NOT NULL,
    [Brand_CC]            VARCHAR (50) NOT NULL,
    [BrandID_BM]          SMALLINT     NOT NULL,
    [Brand_BM]            VARCHAR (50) NOT NULL,
    [BrandMatchNarrative] VARCHAR (50) NOT NULL,
    [BrandMatchID]        INT          NOT NULL,
    [Narrative]           VARCHAR (50) NOT NULL,
    [Combinations]        INT          NULL
);

