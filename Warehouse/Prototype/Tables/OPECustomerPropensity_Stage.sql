CREATE TABLE [Prototype].[OPECustomerPropensity_Stage] (
    [ID]         INT        IDENTITY (1, 1) NOT NULL,
    [BrandID]    SMALLINT   NOT NULL,
    [CINID]      INT        NOT NULL,
    [Propensity] FLOAT (53) NOT NULL,
    [PropClass]  TINYINT    NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

