﻿CREATE TABLE [InsightArchive].[IronOfferCampaignQA_New_V2] (
    [IronOfferID]           INT           NOT NULL,
    [PartnerID]             INT           NOT NULL,
    [RetailerID]            INT           NOT NULL,
    [Retailer]              VARCHAR (100) NOT NULL,
    [PublisherID]           INT           NOT NULL,
    [Publisher]             VARCHAR (50)  NOT NULL,
    [PositiveTranCount]     INT           NOT NULL,
    [IronOfferName]         VARCHAR (100) NOT NULL,
    [StartDate]             DATE          NULL,
    [EndDate]               DATE          NULL,
    [IsAppliedToAllMembers] BIT           NULL,
    [AboveBase]             BIT           NULL,
    [CampaignType]          VARCHAR (100) NULL,
    [EndsInPeriod]          BIT           NOT NULL,
    [CycleStartDate]        DATETIME      NULL,
    [CycleEndDate]          DATETIME      NULL,
    [CycleInPeriod]         INT           NOT NULL
);

