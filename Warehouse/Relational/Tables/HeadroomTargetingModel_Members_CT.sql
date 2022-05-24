﻿CREATE TABLE [Relational].[HeadroomTargetingModel_Members_CT] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [HTMID]     INT  NOT NULL,
    [PartnerID] INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

