CREATE TABLE [MI].[StagingPrep_1_NoDupes] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [FanID]             INT          NULL,
    [ProgramID]         INT          NULL,
    [PartnerID]         INT          NULL,
    [ClientServicesRef] VARCHAR (10) NULL,
    [CumulativeTypeID]  INT          NULL,
    [PeriodTypeID]      INT          NULL,
    [DateID]            INT          NULL,
    [StartDate]         DATE         NULL,
    [EndDate]           DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

