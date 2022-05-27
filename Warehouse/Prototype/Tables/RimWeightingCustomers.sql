CREATE TABLE [Prototype].[RimWeightingCustomers] (
    [CINID]             INT            NOT NULL,
    [PostalSector]      VARCHAR (6)    NULL,
    [Gender]            CHAR (1)       NULL,
    [Region]            VARCHAR (30)   NULL,
    [AgeGroup]          VARCHAR (12)   NULL,
    [Age_Group]         INT            NULL,
    [CameoGroup]        VARCHAR (151)  NOT NULL,
    [MarketableByEmail] BIT            NULL,
    [SocialClass]       NVARCHAR (255) NOT NULL,
    [Social_Class]      INT            NOT NULL
);

