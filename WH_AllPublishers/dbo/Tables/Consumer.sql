﻿CREATE TABLE [dbo].[Consumer] (
    [ConsumerID]         INT           IDENTITY (1, 1) NOT NULL,
    [FanID]              INT           NOT NULL,
    [ClubID]             INT           NULL,
    [PublisherID]        INT           NULL,
    [AccountType]        VARCHAR (20)  NULL,
    [Title]              VARCHAR (20)  NULL,
    [City]               VARCHAR (100) NULL,
    [County]             VARCHAR (100) NULL,
    [Region]             VARCHAR (30)  NULL,
    [PostalSector]       VARCHAR (6)   NULL,
    [PostCodeDistrict]   VARCHAR (4)   NULL,
    [PostArea]           VARCHAR (2)   NULL,
    [Gender]             CHAR (1)      NULL,
    [AgeCurrent]         TINYINT       NULL,
    [AgeCurrentBandText] VARCHAR (10)  NULL,
    [MarketableByEmail]  BIT           NULL,
    [MarketableByPush]   BIT           NULL,
    [CurrentlyActive]    BIT           NULL,
    [RegistrationDate]   DATE          NULL,
    [DeactivatedDate]    DATE          NULL,
    [SourceID]           VARCHAR (36)  NOT NULL,
    [SourceTypeID]       INT           NOT NULL,
    [CreatedDateTime]    DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]    DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Consumer] PRIMARY KEY CLUSTERED ([ConsumerID] ASC),
    CONSTRAINT [FK_Consumer_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);
