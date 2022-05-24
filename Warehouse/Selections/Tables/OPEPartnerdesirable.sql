CREATE TABLE [Selections].[OPEPartnerdesirable] (
    [PartnerID] INT         NOT NULL,
    [Gender]    CHAR (1)    NULL,
    [AgeMin]    TINYINT     NULL,
    [AgeMax]    TINYINT     NULL,
    [Private]   BIT         NULL,
    [CameoMin]  VARCHAR (2) NULL,
    [CameoMax]  VARCHAR (2) NULL,
    [LiveRule]  BIT         NULL
);

