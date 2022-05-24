﻿CREATE TABLE [APW].[DirectLoad_PublisherExclude] (
    [ID]          INT  IDENTITY (1, 1) NOT NULL,
    [RetailerID]  INT  NOT NULL,
    [PublisherID] INT  NOT NULL,
    [StartDate]   DATE NOT NULL,
    [EndDate]     DATE NOT NULL,
    CONSTRAINT [PK_APW_DirectLoad_PublisherExclude] PRIMARY KEY CLUSTERED ([ID] ASC)
);

