﻿CREATE TABLE [Staging].[ControlSetup_Validation_VirginNonAAM_Segments] (
    [PublisherType] VARCHAR (50)   NULL,
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATE           NOT NULL,
    [EndDate]       DATE           NOT NULL,
    [PartnerID]     INT            NULL,
    [ClubID]        INT            NULL,
    [PartnerName]   VARCHAR (200)  NULL,
    [Segment]       VARCHAR (10)   NULL,
    CONSTRAINT [PK_ControlSetup_Validation_VirginNonAAM_Segments] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

