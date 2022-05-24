CREATE TABLE [Prototype].[OPECustomerPropensity] (
    [ID]         INT        IDENTITY (1, 1) NOT NULL,
    [BrandID]    SMALLINT   NOT NULL,
    [CINID]      INT        NOT NULL,
    [Propensity] FLOAT (53) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

