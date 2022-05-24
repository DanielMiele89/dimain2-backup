﻿CREATE TABLE [MI].[MRR_Staging_NonCoreCustomers_Stage1] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [FanID]             INT           NULL,
    [ProgramID]         INT           NULL,
    [PartnerID]         INT           NULL,
    [ClientServicesRef] NVARCHAR (30) NULL,
    [CumulativeTypeID]  INT           NULL,
    [PeriodTypeID]      INT           NULL,
    [DateID]            INT           NULL,
    [StartDate]         DATE          NULL,
    [EndDate]           DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

