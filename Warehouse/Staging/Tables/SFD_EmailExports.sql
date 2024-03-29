﻿CREATE TABLE [Staging].[SFD_EmailExports] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [AgreedTcsDate]         DATETIME       NULL,
    [ClubCashAvailable]     FLOAT (53)     NULL,
    [ClubCashPending]       FLOAT (53)     NULL,
    [ClubID]                FLOAT (53)     NULL,
    [LionSendID]            INT            NULL,
    [customer id]           FLOAT (53)     NULL,
    [CustomerJourneyStatus] NVARCHAR (255) NULL,
    [Email]                 NVARCHAR (255) NULL,
    [Email Permission]      FLOAT (53)     NULL,
    [MOT1-week]             FLOAT (53)     NULL,
    [MOT2-week]             FLOAT (53)     NULL,
    [MOT3-week]             NVARCHAR (255) NULL,
    [POCcustomer]           NVARCHAR (255) NULL,
    [Offer1]                INT            NULL,
    [Offer2]                INT            NULL,
    [Offer3]                INT            NULL,
    [Offer4]                INT            NULL,
    [Offer5]                INT            NULL,
    [Offer6]                INT            NULL,
    [Offer7]                INT            NULL,
    [partial postcode]      VARCHAR (8)    NULL,
    [SMS Permission]        INT            NULL,
    [EmailDate]             DATE           NOT NULL,
    [EmailType]             CHAR (1)       NOT NULL
);

