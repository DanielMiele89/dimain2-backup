﻿CREATE TABLE [Staging].[WelcomeIronOfferMembers_20200108] (
    [ID]                        BIGINT           IDENTITY (1, 1) NOT NULL,
    [WelcomeIronOfferMembersID] UNIQUEIDENTIFIER NOT NULL,
    [CustomerGUID]              UNIQUEIDENTIFIER NULL,
    [OfferGUID]                 UNIQUEIDENTIFIER NULL,
    [StartDate]                 DATETIME2 (7)    NULL,
    [EndDate]                   DATETIME2 (7)    NULL,
    [LoadDate]                  DATETIME2 (7)    NOT NULL,
    [FileName]                  NVARCHAR (320)   NOT NULL
);

