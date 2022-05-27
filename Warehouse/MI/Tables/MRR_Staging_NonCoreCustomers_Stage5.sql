CREATE TABLE [MI].[MRR_Staging_NonCoreCustomers_Stage5] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [FanID]             INT           NULL,
    [ProgramID]         INT           NULL,
    [PartnerID]         INT           NULL,
    [ClientServicesRef] NVARCHAR (30) NOT NULL,
    [CumulativeTypeID]  INT           NULL,
    [PeriodTypeID]      INT           NULL,
    [DateID]            INT           NULL,
    [StartDate]         DATE          NULL,
    [EndDate]           DATE          NULL,
    [CustType_ECR]      CHAR (1)      NULL,
    [CustType_ECY]      CHAR (1)      NULL,
    [CustType_EC]       CHAR (1)      NULL,
    [FirstMonth]        INT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

