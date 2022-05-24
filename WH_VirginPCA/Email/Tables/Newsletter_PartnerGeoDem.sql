CREATE TABLE [Email].[Newsletter_PartnerGeoDem] (
    [ID]        INT         IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT         NOT NULL,
    [Gender]    CHAR (1)    NULL,
    [AgeMin]    TINYINT     NULL,
    [AgeMax]    TINYINT     NULL,
    [Private]   BIT         NULL,
    [CameoMin]  VARCHAR (2) NULL,
    [CameoMax]  VARCHAR (2) NULL,
    [StartDate] DATE        NOT NULL,
    [EndDate]   DATE        NULL,
    [LiveRule]  BIT         NULL
);

