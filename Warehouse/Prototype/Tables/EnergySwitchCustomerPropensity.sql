CREATE TABLE [Prototype].[EnergySwitchCustomerPropensity] (
    [ID]         INT        IDENTITY (1, 1) NOT NULL,
    [CINID]      INT        NOT NULL,
    [Propensity] FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

