CREATE TABLE [Inbound].[nFI_Customer] (
    [FanID]             INT          NOT NULL,
    [CompositeID]       BIGINT       NULL,
    [SourceUID]         VARCHAR (20) NULL,
    [ClubID]            SMALLINT     NULL,
    [Gender]            CHAR (1)     NULL,
    [DOB]               DATE         NULL,
    [PostCode]          VARCHAR (10) NULL,
    [PostalSector]      VARCHAR (6)  NULL,
    [PostAreaCode]      VARCHAR (2)  NULL,
    [Region]            VARCHAR (30) NULL,
    [RegistrationDate]  DATETIME     NULL,
    [Status]            BIT          NULL,
    [AgeCurrent]        TINYINT      NULL,
    [ClubCashPending]   SMALLMONEY   NULL,
    [ClubCashAvailable] SMALLMONEY   NULL
);

